package Paws::S3::QueueConfiguration {
  use Moose;
  has Events => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'Event', request_name => 'Event', traits => ['Unwrapped','NameInRequest'], required => 1);
  has Id => (is => 'ro', isa => 'Str');
  has QueueArn => (is => 'ro', isa => 'Str', xmlname => 'Queue', request_name => 'Queue', traits => ['Unwrapped','NameInRequest'], required => 1);
}
1;
