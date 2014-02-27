package MojoForum;
use Mojo::Base 'Mojolicious';

use MojoForum::Model ();

has model => sub { MojoForum::Model->connect('mongodb://localhost/mojoforum') };

sub startup {
  my $app = shift;
  $app->plugin('MojoForum::Helpers');

  my $r = $app->routes;
  $r->any('/' => 'index');
  $r->any('/login')->to('access#login');
  $r->any('/logout')->to('access#logout');
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
      my ($delay, $user, $err) = @_;
      die $err if $err;
      $app->create_thread($user, 'My first thread', 'My first post', $delay->begin);
    },
    sub { say 'Done' },
  );
  $delay->on(error => sub { say pop });
  $delay->wait unless $delay->ioloop->is_running;
}


1;


