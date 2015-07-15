package Paws::EC2::DiskImage {
  use Moose;
  has Description => (is => 'ro', isa => 'Str');
  has Image => (is => 'ro', isa => 'Paws::EC2::DiskImageDetail');
  has Volume => (is => 'ro', isa => 'Paws::EC2::VolumeDetail');
}
1;
