package Paws::EC2::DiskImageDescription {
  use Moose;
  has Checksum => (is => 'ro', isa => 'Str', xmlname => 'checksum', traits => ['Unwrapped']);
  has Format => (is => 'ro', isa => 'Str', xmlname => 'format', traits => ['Unwrapped'], required => 1);
  has ImportManifestUrl => (is => 'ro', isa => 'Str', xmlname => 'importManifestUrl', traits => ['Unwrapped'], required => 1);
  has Size => (is => 'ro', isa => 'Int', xmlname => 'size', traits => ['Unwrapped'], required => 1);
}
1;
