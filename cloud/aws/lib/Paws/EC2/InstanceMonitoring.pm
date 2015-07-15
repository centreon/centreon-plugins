package Paws::EC2::InstanceMonitoring {
  use Moose;
  has InstanceId => (is => 'ro', isa => 'Str', xmlname => 'instanceId', traits => ['Unwrapped']);
  has Monitoring => (is => 'ro', isa => 'Paws::EC2::Monitoring', xmlname => 'monitoring', traits => ['Unwrapped']);
}
1;
