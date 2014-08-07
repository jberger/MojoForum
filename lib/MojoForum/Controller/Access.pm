package MojoForum::Controller::Access;

use Mojo::Base 'Mojolicious::Controller';

sub login {
  my $c = shift;
  return unless uc $c->tx->req->method eq 'POST';
  $c->render_later;
  my $name = $c->param('user_name');
  $c->app->find_user( $name => sub {
    my ($app, $err, $doc) = @_;
    if ($doc and not $err) { 
      $c->session( user_name => $name );
      $c->redirect_to('/');
    } else {
      $c->stash( message => 'Sorry. Your login failed.' );
      $c->render;
    }
  });
}

sub logout {
  my $c = shift;
  delete $c->session->{user_name};
  $c->redirect_to('/');
}

1;

