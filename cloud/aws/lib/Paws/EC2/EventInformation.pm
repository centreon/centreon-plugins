package Paws::EC2::EventInformation {
  use Moose;
  has EventDescription => (is => 'ro', isa => 'Str', xmlname => 'eventDescription', traits => ['Unwrapped']);
  has EventSubType => (is => 'ro', isa => 'Str', xmlname => 'eventSubType', traits => ['Unwrapped']);
  has InstanceId => (is => 'ro', isa => 'Str', xmlname => 'instanceId', traits => ['Unwrapped']);
}
1;
