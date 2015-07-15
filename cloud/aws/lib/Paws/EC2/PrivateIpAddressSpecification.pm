package Paws::EC2::PrivateIpAddressSpecification {
  use Moose;
  has Primary => (is => 'ro', isa => 'Bool', xmlname => 'primary', traits => ['Unwrapped']);
  has PrivateIpAddress => (is => 'ro', isa => 'Str', xmlname => 'privateIpAddress', traits => ['Unwrapped'], required => 1);
}
1;
