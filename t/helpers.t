use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t   = Test::Mojo->new('MojoForum');
my $app = $t->app;

$app->db_url('mongodb://localhost/test');
$app->model->storage->db->command('dropDatabase');
$app->users->create({name => "Joel"})->save;

my ($err, $user);
$app->find_user("Joel" => sub {
  my $c = shift;
  ($err, $user) = @_;
});

is $err, undef, 'No error';
isa_ok $user, 'MojoForum::Model::User';
is $user->name, "Joel";

done_testing;

