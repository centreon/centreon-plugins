package Paws::S3::ReplicationConfiguration {
  use Moose;
  has Role => (is => 'ro', isa => 'Str', required => 1);
  has Rules => (is => 'ro', isa => 'ArrayRef[Paws::S3::ReplicationRule]', xmlname => 'Rule', request_name => 'Rule', traits => ['Unwrapped','NameInRequest'], required => 1);
}
1;
