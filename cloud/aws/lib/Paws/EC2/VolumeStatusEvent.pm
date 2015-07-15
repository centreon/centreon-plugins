package Paws::EC2::VolumeStatusEvent {
  use Moose;
  has Description => (is => 'ro', isa => 'Str', xmlname => 'description', traits => ['Unwrapped']);
  has EventId => (is => 'ro', isa => 'Str', xmlname => 'eventId', traits => ['Unwrapped']);
  has EventType => (is => 'ro', isa => 'Str', xmlname => 'eventType', traits => ['Unwrapped']);
  has NotAfter => (is => 'ro', isa => 'Str', xmlname => 'notAfter', traits => ['Unwrapped']);
  has NotBefore => (is => 'ro', isa => 'Str', xmlname => 'notBefore', traits => ['Unwrapped']);
}
1;
