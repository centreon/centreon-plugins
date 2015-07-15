package Paws::EC2::InstancePrivateIpAddress {
  use Moose;
  has Association => (is => 'ro', isa => 'Paws::EC2::InstanceNetworkInterfaceAssociation', xmlname => 'association', traits => ['Unwrapped']);
  has Primary => (is => 'ro', isa => 'Bool', xmlname => 'primary', traits => ['Unwrapped']);
  has PrivateDnsName => (is => 'ro', isa => 'Str', xmlname => 'privateDnsName', traits => ['Unwrapped']);
  has PrivateIpAddress => (is => 'ro', isa => 'Str', xmlname => 'privateIpAddress', traits => ['Unwrapped']);
}
1;
