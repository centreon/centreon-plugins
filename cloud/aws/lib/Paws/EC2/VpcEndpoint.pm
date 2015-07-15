package Paws::EC2::VpcEndpoint {
  use Moose;
  has CreationTimestamp => (is => 'ro', isa => 'Str', xmlname => 'creationTimestamp', traits => ['Unwrapped']);
  has PolicyDocument => (is => 'ro', isa => 'Str', xmlname => 'policyDocument', traits => ['Unwrapped']);
  has RouteTableIds => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'routeTableIdSet', traits => ['Unwrapped']);
  has ServiceName => (is => 'ro', isa => 'Str', xmlname => 'serviceName', traits => ['Unwrapped']);
  has State => (is => 'ro', isa => 'Str', xmlname => 'state', traits => ['Unwrapped']);
  has VpcEndpointId => (is => 'ro', isa => 'Str', xmlname => 'vpcEndpointId', traits => ['Unwrapped']);
  has VpcId => (is => 'ro', isa => 'Str', xmlname => 'vpcId', traits => ['Unwrapped']);
}
1;
