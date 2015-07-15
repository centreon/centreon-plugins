package Paws::EC2::Route {
  use Moose;
  has DestinationCidrBlock => (is => 'ro', isa => 'Str', xmlname => 'destinationCidrBlock', traits => ['Unwrapped']);
  has DestinationPrefixListId => (is => 'ro', isa => 'Str', xmlname => 'destinationPrefixListId', traits => ['Unwrapped']);
  has GatewayId => (is => 'ro', isa => 'Str', xmlname => 'gatewayId', traits => ['Unwrapped']);
  has InstanceId => (is => 'ro', isa => 'Str', xmlname => 'instanceId', traits => ['Unwrapped']);
  has InstanceOwnerId => (is => 'ro', isa => 'Str', xmlname => 'instanceOwnerId', traits => ['Unwrapped']);
  has NetworkInterfaceId => (is => 'ro', isa => 'Str', xmlname => 'networkInterfaceId', traits => ['Unwrapped']);
  has Origin => (is => 'ro', isa => 'Str', xmlname => 'origin', traits => ['Unwrapped']);
  has State => (is => 'ro', isa => 'Str', xmlname => 'state', traits => ['Unwrapped']);
  has VpcPeeringConnectionId => (is => 'ro', isa => 'Str', xmlname => 'vpcPeeringConnectionId', traits => ['Unwrapped']);
}
1;
