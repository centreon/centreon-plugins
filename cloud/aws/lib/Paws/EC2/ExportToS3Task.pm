package Paws::EC2::ExportToS3Task {
  use Moose;
  has ContainerFormat => (is => 'ro', isa => 'Str', xmlname => 'containerFormat', traits => ['Unwrapped']);
  has DiskImageFormat => (is => 'ro', isa => 'Str', xmlname => 'diskImageFormat', traits => ['Unwrapped']);
  has S3Bucket => (is => 'ro', isa => 'Str', xmlname => 's3Bucket', traits => ['Unwrapped']);
  has S3Key => (is => 'ro', isa => 'Str', xmlname => 's3Key', traits => ['Unwrapped']);
}
1;
