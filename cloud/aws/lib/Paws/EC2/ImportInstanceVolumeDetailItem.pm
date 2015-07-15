package Paws::EC2::ImportInstanceVolumeDetailItem {
  use Moose;
  has AvailabilityZone => (is => 'ro', isa => 'Str', xmlname => 'availabilityZone', traits => ['Unwrapped'], required => 1);
  has BytesConverted => (is => 'ro', isa => 'Int', xmlname => 'bytesConverted', traits => ['Unwrapped'], required => 1);
  has Description => (is => 'ro', isa => 'Str', xmlname => 'description', traits => ['Unwrapped']);
  has Image => (is => 'ro', isa => 'Paws::EC2::DiskImageDescription', xmlname => 'image', traits => ['Unwrapped'], required => 1);
  has Status => (is => 'ro', isa => 'Str', xmlname => 'status', traits => ['Unwrapped'], required => 1);
  has StatusMessage => (is => 'ro', isa => 'Str', xmlname => 'statusMessage', traits => ['Unwrapped']);
  has Volume => (is => 'ro', isa => 'Paws::EC2::DiskImageVolumeDescription', xmlname => 'volume', traits => ['Unwrapped'], required => 1);
}
1;
