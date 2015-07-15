package Paws::EC2::EbsInstanceBlockDevice {
  use Moose;
  has AttachTime => (is => 'ro', isa => 'Str', xmlname => 'attachTime', traits => ['Unwrapped']);
  has DeleteOnTermination => (is => 'ro', isa => 'Bool', xmlname => 'deleteOnTermination', traits => ['Unwrapped']);
  has Status => (is => 'ro', isa => 'Str', xmlname => 'status', traits => ['Unwrapped']);
  has VolumeId => (is => 'ro', isa => 'Str', xmlname => 'volumeId', traits => ['Unwrapped']);
}
1;
