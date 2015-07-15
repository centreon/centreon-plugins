package Paws::S3::Delete {
  use Moose;
  has Objects => (is => 'ro', isa => 'ArrayRef[Paws::S3::ObjectIdentifier]', xmlname => 'Object', request_name => 'Object', traits => ['Unwrapped','NameInRequest'], required => 1);
  has Quiet => (is => 'ro', isa => 'Bool');
}
1;
