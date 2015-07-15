package Paws::EC2::DiskImageDetail {
  use Moose;
  has Bytes => (is => 'ro', isa => 'Int', xmlname => 'bytes', traits => ['Unwrapped'], required => 1);
  has Format => (is => 'ro', isa => 'Str', xmlname => 'format', traits => ['Unwrapped'], required => 1);
  has ImportManifestUrl => (is => 'ro', isa => 'Str', xmlname => 'importManifestUrl', traits => ['Unwrapped'], required => 1);
}
1;
