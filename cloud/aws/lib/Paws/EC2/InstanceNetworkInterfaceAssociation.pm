package Paws::EC2::InstanceNetworkInterfaceAssociation {
  use Moose;
  has IpOwnerId => (is => 'ro', isa => 'Str', xmlname => 'ipOwnerId', traits => ['Unwrapped']);
  has PublicDnsName => (is => 'ro', isa => 'Str', xmlname => 'publicDnsName', traits => ['Unwrapped']);
  has PublicIp => (is => 'ro', isa => 'Str', xmlname => 'publicIp', traits => ['Unwrapped']);
}
1;
