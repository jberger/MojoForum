package MojoForum::Helpers;

use Mojo::Base 'Mojolicious::Plugin';
use Mango::BSON 'bson_oid';

sub register {
  my ($self, $app) = @_;
  $app->helper( delay => \&delay );
  
  $app->helper( users   => sub { $_[0]->app->model->collection('user') } );
  $app->helper( threads => sub { $_[0]->app->model->collection('thread') } );
  $app->helper( posts   => sub { $_[0]->app->model->collection('post') } );

  $app->helper( find_user => \&find_user );
  $app->helper( find_user_posts => \&find_user_posts );
  $app->helper( find_user_threads => \&find_user_threads );

  $app->helper( create_thread => \&create_thread );
  $app->helper( find_thread => \&find_thread );

  $app->helper( add_post => \&add_post );
}

sub delay {
  my $self = shift;
  my $opts = ref $_[0] eq 'HASH' ? shift : {};
  my $delay = Mojo::IOLoop->delay(@_);
  for my $event (keys %$opts) {
    $delay->on( $event => $opts->{$event} );
  }
  unless ($opts->{no_wait}) {
    $delay->wait unless $delay->ioloop->is_running;
  }
  return $delay;
}

sub find_user {
  my ($c, $user, $cb) = @_;
  $c->delay(
    { error => $cb },
    sub{
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
}

sub find_thread {
  my ($c, $thread, $cb) = @_;
  $c->delay(
    { error => $cb },
    sub{
      my $delay = shift;
      if (ref $thread) {
        $delay->pass(undef, $thread);
      } else {
        $c->threads->search({ _id => bson_oid($thread) })->single($delay->begin);
      }
    },
    sub {
      my ($delay, $err, $thread) = @_;
      $c->$cb($err, $thread);
    }
  );
}

sub find_user_posts {
  my ($c, $user, $cb) = @_;
  $c->delay(
    { error => $cb },
    sub { $c->find_user($user, shift->begin) },
    sub {
      my ($delay, $err, $user) = @_;
      die $err if $err;
      $user->posts($delay->begin);
    },
    sub {
      my ($delay, $err, $posts) = @_;
      $c->$cb($err, $posts);
    },
  );
}

sub find_user_threads {
  my ($c, $user, $cb) = @_;
  $c->delay(
    { error => $cb },
    sub { $c->find_user($user, shift->begin) },
    sub {
      my ($delay, $err, $user) = @_;
      die $err if $err;
      $user->threads($delay->begin);
    },
    sub {
      my ($delay, $err, $threads) = @_;
      $c->$cb($err, $threads);
    },
  );
}

sub add_post {
  my ($c, $thread, $user, $content, $cb) = @_;
  $c->delay(
    { error => $cb },
    sub {
      my $delay = shift;
      $c->find_user($user,     $delay->begin);
      $c->find_thread($thread, $delay->begin);
    },
    sub {
      my ($delay, $u_err, $user, $t_err, $thread) = @_;
      die $u_err if $u_err;
      die $t_err if $t_err;
      my $post = $c->posts->create({ content => $content });
      $user->add_posts($post,   $delay->begin);
      $thread->add_posts($post, $delay->begin);
    },
    sub {
      my ($delay, $u_err, $post, $t_err) = @_;
      die $u_err if $u_err;
      die $t_err if $t_err;
      $c->$cb(undef, $post) if $cb;
    },
  );
}

sub create_thread {
  my ($c, $user, $title, $content, $cb) = @_;
  $c->delay(
    { error => $cb },
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
      $delay->pass($user, $thread);
      $user->add_posts($post, $delay->begin);
      $thread->add_posts($post, $delay->begin);
    },
    sub {
      my ($delay, $user, $thread, $u_err, $post, $t_err) = @_;
      die $u_err if $u_err;
      die $t_err if $t_err;
      $c->$cb(undef, $user, $thread, $post) if $cb;
    },
  );
}

1;

