package Paws::EC2::ActiveInstance {
  use Moose;
  has InstanceId => (is => 'ro', isa => 'Str', xmlname => 'instanceId', traits => ['Unwrapped']);
  has InstanceType => (is => 'ro', isa => 'Str', xmlname => 'instanceType', traits => ['Unwrapped']);
  has SpotInstanceRequestId => (is => 'ro', isa => 'Str', xmlname => 'spotInstanceRequestId', traits => ['Unwrapped']);
}
1;
