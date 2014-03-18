package MojoForum::Model::Thread;
use Mandel::Document;
use Types::Standard qw/Str/;

field title => ( isa => Str );

belongs_to creator => 'MojoForum::Model::User';

has_many posts => 'MojoForum::Model::Post', foreign_field => 'thread';

has 'cached_creator' => sub { die 'Creator has not been cached' };

sub cache_creator {
  my ($self, $sub) = @_;
  $self->creator(sub{
    my ($self, $err, $creator) = @_;
    # because this dies on error, be sure to install on error handler in controller!
    die $err if $err;
    $self->cached_creator($creator);
    $sub->(@_);
  });
}

1;

