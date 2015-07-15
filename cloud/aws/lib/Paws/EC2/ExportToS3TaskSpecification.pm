package Paws::EC2::ExportToS3TaskSpecification {
  use Moose;
  has ContainerFormat => (is => 'ro', isa => 'Str', xmlname => 'containerFormat', traits => ['Unwrapped']);
  has DiskImageFormat => (is => 'ro', isa => 'Str', xmlname => 'diskImageFormat', traits => ['Unwrapped']);
  has S3Bucket => (is => 'ro', isa => 'Str', xmlname => 's3Bucket', traits => ['Unwrapped']);
  has S3Prefix => (is => 'ro', isa => 'Str', xmlname => 's3Prefix', traits => ['Unwrapped']);
}
1;
