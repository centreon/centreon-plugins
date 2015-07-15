package Paws::S3::LifecycleConfiguration {
  use Moose;
  has Rules => (is => 'ro', isa => 'ArrayRef[Paws::S3::Rule]', xmlname => 'Rule', request_name => 'Rule', traits => ['Unwrapped','NameInRequest'], required => 1);
}
1;
