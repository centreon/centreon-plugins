package Paws::EC2::S3Storage {
  use Moose;
  has AWSAccessKeyId => (is => 'ro', isa => 'Str');
  has Bucket => (is => 'ro', isa => 'Str', xmlname => 'bucket', traits => ['Unwrapped']);
  has Prefix => (is => 'ro', isa => 'Str', xmlname => 'prefix', traits => ['Unwrapped']);
  has UploadPolicy => (is => 'ro', isa => 'Str', xmlname => 'uploadPolicy', traits => ['Unwrapped']);
  has UploadPolicySignature => (is => 'ro', isa => 'Str', xmlname => 'uploadPolicySignature', traits => ['Unwrapped']);
}
1;
