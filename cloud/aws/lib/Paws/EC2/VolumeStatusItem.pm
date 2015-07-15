package Paws::EC2::VolumeStatusItem {
  use Moose;
  has Actions => (is => 'ro', isa => 'ArrayRef[Paws::EC2::VolumeStatusAction]', xmlname => 'actionsSet', traits => ['Unwrapped']);
  has AvailabilityZone => (is => 'ro', isa => 'Str', xmlname => 'availabilityZone', traits => ['Unwrapped']);
  has Events => (is => 'ro', isa => 'ArrayRef[Paws::EC2::VolumeStatusEvent]', xmlname => 'eventsSet', traits => ['Unwrapped']);
  has VolumeId => (is => 'ro', isa => 'Str', xmlname => 'volumeId', traits => ['Unwrapped']);
  has VolumeStatus => (is => 'ro', isa => 'Paws::EC2::VolumeStatusInfo', xmlname => 'volumeStatus', traits => ['Unwrapped']);
}
1;
