package MojoForum::Threads;

use Mojo::Base 'Mojolicious::Controller';

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

