package Paws::EC2::DhcpOptions {
  use Moose;
  has DhcpConfigurations => (is => 'ro', isa => 'ArrayRef[Paws::EC2::DhcpConfiguration]', xmlname => 'dhcpConfigurationSet', traits => ['Unwrapped']);
  has DhcpOptionsId => (is => 'ro', isa => 'Str', xmlname => 'dhcpOptionsId', traits => ['Unwrapped']);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', xmlname => 'tagSet', traits => ['Unwrapped']);
}
1;
