package MojoForum::Model::User;
use Mandel::Document;
use Types::Standard qw/Str Int/;

field name => ( isa => Str );

has_many posts   => 'MojoForum::Model::Post'   => ( foreign_field => 'author'  );
has_many threads => 'MojoForum::Model::Thread' => ( foreign_field => 'creator' );

1;

