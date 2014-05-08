package MojoForum::Threads;

use Mojo::Base 'Mojolicious::Controller';

sub post {
  my $self = shift;
  my $id   = $self->stash('thread_id');
  my $user = $self->session('user_name');
  return $self->render( text => 'forbidden' ) unless $user;
  $self->render_later;
  my $content = $self->param('content');
  my $delay = Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $self->add_post( $id, $user, $content, $delay->begin );
    },
    sub {
      my ($delay, $err, $post) = @_;
      die $err if $err;
      $self->redirect_to( thread => {'thread_id' => $id} );
    },
  );
  $delay->on( error => sub {
    $self->app->log->error($_[1]);
    $self->render_not_found;
  } );
  $delay->wait unless $delay->ioloop->is_running;
}

sub single {
  my $self = shift;
  my $id = $self->stash('thread_id');
  $self->render_later;
  my $delay = Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      $self->find_thread( $id => $delay->begin );
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
      $_->cache_author($delay->begin) for @$posts;
    },
    sub {
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

