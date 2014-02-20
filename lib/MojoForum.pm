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

sub create_thread {
  my ($app, $user, $title, $content, $cb) = @_;
  my $delay = Mojo::IOLoop->delay(
    $app->_find_user_step($user),
    sub {
      my ($delay, $err, $user) = @_;
      my $thread = $app->threads->create({ title => $title });
      $user->add_threads($thread, $delay->begin(0));
    },
    sub { 
      my ($delay, $user, $err, $thread) = @_;
      my $post = $app->posts->create({ content => $content });
      $user->add_posts($post, $delay->begin(0));
      $thread->add_posts($post, $delay->begin(0));
    },
    sub {
      my ($delay, $u, $u_err, $post, $t, $t_err) = @_;
      $cb->($u_err || $t_err, $u, $t, $post) if $cb;
    },
  );
  $delay->wait unless $delay->ioloop->is_running;
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
      $app->create_thread($user, 'My first thread', 'My first post', $delay->begin);
    },
    sub {
      say 'Done';
    },
  );
  $delay->wait unless $delay->ioloop->is_running;
}

sub find_user_posts {
  my ($app, $user, $cb) = @_;
  my $delay = Mojo::IOLoop->delay(
    $app->_find_user_step($user),
    sub {
      my ($delay, $err, $user) = @_;
      $user->posts($delay->begin);
    },
    sub {
      my ($delay, $err, $posts) = @_;
      $app->$cb($err, $posts);
    },
  );
  $delay->wait unless $delay->ioloop->is_running;
};

sub find_user_threads {
  my ($app, $user, $cb) = @_;
  my $delay = Mojo::IOLoop->delay(
    $app->_find_user_step($user),
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

sub _find_user_step {
  my ($app, $user) = @_;
  return sub {
    my $delay = shift;
    my $end   = $delay->begin;
    if (ref $user) {
      $end->(undef, undef, $user);
    } else {
      $user = $app->users->search({ name => $user })->single($end);
    }
  },
}

1;


