package MojoForum::Threads;

use Mojo::Base 'Mojolicious::Controller';
use Mango::BSON 'bson_oid';

sub single {
  my $self = shift;
  my $id = $self->stash('thread_id');
  $self->render_later;
  my $delay = Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $self->threads->search({ _id => bson_oid($id) })->single($delay->begin);
    },
    sub {
      my ($delay, $err, $thread) = @_;
      die $err if $err;
      $self->stash( thread => $thread );
      $thread->posts($delay->begin);
    },
    sub {
      my ($delay, $err, $posts) = @_;
      die $err if $err;
      $self->stash( posts => $posts );
      $self->render;
    },
  );
  $delay->on( error => sub {
    $self->app->log->error($_[1]);
    $self->render_not_found;
  } );
  $delay->wait unless $delay->ioloop->is_running;
}

sub toplevel {
  my $self = shift;
  $self->render_later;
  my $delay = Mojo::IOLoop->delay(
    sub {
      $self->threads->all(shift->begin)
    },
    sub {
      my ($delay, $err, $threads) = @_;
      die $err if $err;
      $self->stash(threads => $threads);
      foreach my $thread (@$threads) {
        $thread->cache_creator($delay->begin);
      }
    },
    sub {
      $self->render; #('threads/toplevel');
    },
  );
  # cache_creator dies on error, therefore need this handler
  $delay->on(error => sub { $self->render_exception($_[1]) });
  $delay->wait unless $delay->ioloop->is_running;
}

1;

