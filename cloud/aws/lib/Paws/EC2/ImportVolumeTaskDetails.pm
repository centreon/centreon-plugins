package Paws::EC2::ImportVolumeTaskDetails {
  use Moose;
  has AvailabilityZone => (is => 'ro', isa => 'Str', xmlname => 'availabilityZone', traits => ['Unwrapped'], required => 1);
  has BytesConverted => (is => 'ro', isa => 'Int', xmlname => 'bytesConverted', traits => ['Unwrapped'], required => 1);
  has Description => (is => 'ro', isa => 'Str', xmlname => 'description', traits => ['Unwrapped']);
  has Image => (is => 'ro', isa => 'Paws::EC2::DiskImageDescription', xmlname => 'image', traits => ['Unwrapped'], required => 1);
  has Volume => (is => 'ro', isa => 'Paws::EC2::DiskImageVolumeDescription', xmlname => 'volume', traits => ['Unwrapped'], required => 1);
}
1;
