package Paws::EC2::VolumeStatusInfo {
  use Moose;
  has Details => (is => 'ro', isa => 'ArrayRef[Paws::EC2::VolumeStatusDetails]', xmlname => 'details', traits => ['Unwrapped']);
  has Status => (is => 'ro', isa => 'Str', xmlname => 'status', traits => ['Unwrapped']);
}
1;
