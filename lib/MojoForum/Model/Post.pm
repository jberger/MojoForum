package MojoForum::Model::Post;
use Mandel::Document;
use Types::Standard 'Str';

field content => ( isa => Str );

belongs_to thread => 'MojoForum::Model::Thread';
belongs_to author => 'MojoForum::Model::User';

1;

