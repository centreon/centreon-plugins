package Paws::S3::TopicConfiguration {
  use Moose;
  has Events => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'Event', request_name => 'Event', traits => ['Unwrapped','NameInRequest'], required => 1);
  has Id => (is => 'ro', isa => 'Str');
  has TopicArn => (is => 'ro', isa => 'Str', xmlname => 'Topic', request_name => 'Topic', traits => ['Unwrapped','NameInRequest'], required => 1);
}
1;
