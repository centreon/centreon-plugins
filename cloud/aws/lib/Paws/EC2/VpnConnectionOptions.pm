package Paws::EC2::VpnConnectionOptions {
  use Moose;
  has StaticRoutesOnly => (is => 'ro', isa => 'Bool', xmlname => 'staticRoutesOnly', traits => ['Unwrapped']);
}
1;
