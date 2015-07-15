package Paws::EC2::UserBucketDetails {
  use Moose;
  has S3Bucket => (is => 'ro', isa => 'Str', xmlname => 's3Bucket', traits => ['Unwrapped']);
  has S3Key => (is => 'ro', isa => 'Str', xmlname => 's3Key', traits => ['Unwrapped']);
}
1;
