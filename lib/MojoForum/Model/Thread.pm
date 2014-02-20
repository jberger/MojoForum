package MojoForum::Model::Thread;
use Mandel::Document;
use Types::Standard qw/Str/;

field title => ( isa => Str );

belongs_to creator => 'MojoForum::Model::User';

has_many posts => 'MojoForum::Model::Post', foreign_field => 'thread';

1;

