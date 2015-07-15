package Paws::EC2::NetworkInterfacePrivateIpAddress {
  use Moose;
  has Association => (is => 'ro', isa => 'Paws::EC2::NetworkInterfaceAssociation', xmlname => 'association', traits => ['Unwrapped']);
  has Primary => (is => 'ro', isa => 'Bool', xmlname => 'primary', traits => ['Unwrapped']);
  has PrivateDnsName => (is => 'ro', isa => 'Str', xmlname => 'privateDnsName', traits => ['Unwrapped']);
  has PrivateIpAddress => (is => 'ro', isa => 'Str', xmlname => 'privateIpAddress', traits => ['Unwrapped']);
}
1;
