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
      foreach my $thread (@$threads) {
        my $end = $delay->begin(0);
        $thread->creator(sub{
          my ($thread, $err, $creator) = @_;
          die $err if $err;
          $end->([$thread, $creator]);
        });
      }
    },
    sub {
      my ($delay, @threads) = @_;
      $self->stash(threads => \@threads);
      $self->render; #('threads/toplevel');
    },
  );
  $delay->on(error => sub { $self->render($_[-1]) });
}

1;

