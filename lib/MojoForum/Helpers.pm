package MojoForum::Helpers;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($self, $app) = @_;
  $app->helper( users   => sub { $_[0]->app->model->collection('user') } );
  $app->helper( threads => sub { $_[0]->app->model->collection('thread') } );
  $app->helper( posts   => sub { $_[0]->app->model->collection('post') } );

  $app->helper( find_user => \&find_user );
  $app->helper( find_user_posts => \&find_user_posts );
  $app->helper( find_user_threads => \&find_user_threads );
  $app->helper( create_thread => \&create_thread );
}

sub find_user {
  my ($c, $user, $cb) = @_;
  my $delay = Mojo::IOLoop->delay(sub{
      my $delay = shift;
      if (ref $user) {
        $delay->pass(undef, $user);
      } else {
        $c->app->users->search({ name => $user })->single($delay->begin);
      }
    },
    sub {
      my ($delay, $err, $user) = @_;
      $c->$cb($err, $user);
    }
  );
  $delay->wait unless $delay->ioloop->is_running;
}

sub find_user_posts {
  my ($c, $user, $cb) = @_;
  my $delay = Mojo::IOLoop->delay(
    sub { $c->find_user($user, shift->begin) },
    sub {
      my ($delay, $err, $user) = @_;
      return $delay->pass($err) if $err;
      $user->posts($delay->begin);
    },
    sub {
      my ($delay, $err, $posts) = @_;
      $c->$cb($err, $posts);
    },
  );
  $delay->wait unless $delay->ioloop->is_running;
}

sub find_user_threads {
  my ($c, $user, $cb) = @_;
  my $delay = Mojo::IOLoop->delay(
    sub { $c->find_user($user, shift->begin) },
    sub {
      my ($delay, $err, $user) = @_;
      return $delay->pass($err) if $err;
      $user->threads($delay->begin);
    },
    sub {
      my ($delay, $err, $threads) = @_;
      $c->$cb($err, $threads);
    },
  );
  $delay->wait unless $delay->ioloop->is_running;
}

sub create_thread {
  my ($c, $user, $title, $content, $cb) = @_;
  my $delay = Mojo::IOLoop->delay(
    sub { $c->find_user($user, shift->begin) },
    sub {
      my ($delay, $err, $user) = @_;
      die $err if $err;
      my $thread = $c->threads->create({ title => $title });
      $user->add_threads($thread, $delay->begin(0));
    },
    sub { 
      my ($delay, $user, $err, $thread) = @_;
      die $err if $err;
      my $post = $c->posts->create({ content => $content });
      $user->add_posts($post, $delay->begin(0));
      $thread->add_posts($post, $delay->begin(0));
    },
    sub {
      my ($delay, $u, $u_err, $post, $t, $t_err) = @_;
      die $u_err if $u_err;
      die $t_err if $t_err;
      $cb->(undef, $u, $t, $post) if $cb;
    },
  );
  $delay->on(error => sub { shift->$cb(shift) });
  $delay->wait unless $delay->ioloop->is_running;
}

1;

