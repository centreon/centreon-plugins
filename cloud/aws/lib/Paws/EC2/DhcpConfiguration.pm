package Paws::EC2::DhcpConfiguration {
  use Moose;
  has Key => (is => 'ro', isa => 'Str', xmlname => 'key', traits => ['Unwrapped']);
  has Values => (is => 'ro', isa => 'ArrayRef[Paws::EC2::AttributeValue]', xmlname => 'valueSet', traits => ['Unwrapped']);
}
1;
