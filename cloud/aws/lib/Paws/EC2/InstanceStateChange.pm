package Paws::EC2::InstanceStateChange {
  use Moose;
  has CurrentState => (is => 'ro', isa => 'Paws::EC2::InstanceState', xmlname => 'currentState', traits => ['Unwrapped']);
  has InstanceId => (is => 'ro', isa => 'Str', xmlname => 'instanceId', traits => ['Unwrapped']);
  has PreviousState => (is => 'ro', isa => 'Paws::EC2::InstanceState', xmlname => 'previousState', traits => ['Unwrapped']);
}
1;
