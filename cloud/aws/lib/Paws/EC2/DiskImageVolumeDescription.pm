package Paws::EC2::DiskImageVolumeDescription {
  use Moose;
  has Id => (is => 'ro', isa => 'Str', xmlname => 'id', traits => ['Unwrapped'], required => 1);
  has Size => (is => 'ro', isa => 'Int', xmlname => 'size', traits => ['Unwrapped']);
}
1;
