package Paws::EC2::VpnConnectionOptionsSpecification {
  use Moose;
  has StaticRoutesOnly => (is => 'ro', isa => 'Bool', xmlname => 'staticRoutesOnly', traits => ['Unwrapped']);
}
1;
