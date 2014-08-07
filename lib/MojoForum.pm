package MojoForum;
use Mojo::Base 'Mojolicious';

use MojoForum::Model ();

has db_url => 'mongodb://localhost/mojoforum';
has model  => sub { MojoForum::Model->connect(shift->db_url) };

sub startup {
  my $app = shift;

  $app->plugin('MojoForum::Helpers');
  $app->plugin('Bootstrap3');

  my $r = $app->routes;
  $r->namespaces(['MojoForum::Controller']);

  $r->any('/')->to('threads#toplevel');
  $r->any('/thread/:thread_id')->to('threads#single')->name('thread');
  $r->any('/add_post/:thread_id')->to('threads#post')->name('add_post');
  $r->any('/login')->to('access#login');
  $r->any('/logout')->to('access#logout');
}

1;

