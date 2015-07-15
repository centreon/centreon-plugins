package Paws::S3::CompletedMultipartUpload {
  use Moose;
  has Parts => (is => 'ro', isa => 'ArrayRef[Paws::S3::CompletedPart]', xmlname => 'Part', request_name => 'Part', traits => ['Unwrapped','NameInRequest']);
}
1;
