package MojoForum::Model::Post;
use Mandel::Document;
use Types::Standard 'Str';

field content => ( isa => Str );

belongs_to thread => 'MojoForum::Model::Thread';
belongs_to author => 'MojoForum::Model::User';

has 'cached_author' => sub { die 'Author has not been cached' };

sub cache_author {
  my ($self, $sub) = @_;
  $self->author(sub{
    my ($self, $err, $author) = @_;
    # because this dies on error, be sure to install on error handler in controller!
    die $err if $err;
    $self->cached_author($author);
    $sub->(@_);
  });
}

1;

