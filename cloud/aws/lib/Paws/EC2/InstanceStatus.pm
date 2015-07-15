package Paws::EC2::InstanceStatus {
  use Moose;
  has AvailabilityZone => (is => 'ro', isa => 'Str', xmlname => 'availabilityZone', traits => ['Unwrapped']);
  has Events => (is => 'ro', isa => 'ArrayRef[Paws::EC2::InstanceStatusEvent]', xmlname => 'eventsSet', traits => ['Unwrapped']);
  has InstanceId => (is => 'ro', isa => 'Str', xmlname => 'instanceId', traits => ['Unwrapped']);
  has InstanceState => (is => 'ro', isa => 'Paws::EC2::InstanceState', xmlname => 'instanceState', traits => ['Unwrapped']);
  has InstanceStatus => (is => 'ro', isa => 'Paws::EC2::InstanceStatusSummary', xmlname => 'instanceStatus', traits => ['Unwrapped']);
  has SystemStatus => (is => 'ro', isa => 'Paws::EC2::InstanceStatusSummary', xmlname => 'systemStatus', traits => ['Unwrapped']);
}
1;
