package Paws::EC2::VolumeStatusAction {
  use Moose;
  has Code => (is => 'ro', isa => 'Str', xmlname => 'code', traits => ['Unwrapped']);
  has Description => (is => 'ro', isa => 'Str', xmlname => 'description', traits => ['Unwrapped']);
  has EventId => (is => 'ro', isa => 'Str', xmlname => 'eventId', traits => ['Unwrapped']);
  has EventType => (is => 'ro', isa => 'Str', xmlname => 'eventType', traits => ['Unwrapped']);
}
1;
