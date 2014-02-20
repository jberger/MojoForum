package MojoForum;
use Mojo::Base 'Mojolicious';

use MojoForum::Model ();

has model => sub { MojoForum::Model->connect('mongodb://localhost/mojoforum') };

sub startup {
  my $app = shift;
  $app->helper( users   => sub { $_[0]->app->model->collection('user') } );
  $app->helper( threads => sub { $_[0]->app->model->collection('thread') } );
  $app->helper( posts   => sub { $_[0]->app->model->collection('post') } );
}

sub populate {
  my $app = shift;

  my $delay = Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      my $u = $app->users->create({ name => 'Joel' });
      $u->save($delay->begin(0));
    },
    sub {
      my ($delay, $u, $err) = @_;
      my $t = $app->threads->create({ title => 'My first thread!' });
      $u->add_threads($t, $delay->begin);
    },
    sub {
      say 'Done';
    },
  );
  $delay->wait unless $delay->ioloop->is_running;
}

sub find_threads_by_creator {
  my ($app, $user, $cb) = @_;
  my $delay = Mojo::IOLoop->delay(
    sub {
      my $delay = shift;
      my $end   = $delay->begin;
      if (ref $user) {
        $end->(undef, undef, $user);
      } else {
        $user = $app->users->search({ name => $user })->single($end);
      }
    },
    sub {
      my ($delay, $err, $user) = @_;
      $user->threads($delay->begin);
    },
    sub {
      my ($delay, $err, $threads) = @_;
      $app->$cb($err, $threads);
    },
  );
  $delay->wait unless $delay->ioloop->is_running;
};

1;


