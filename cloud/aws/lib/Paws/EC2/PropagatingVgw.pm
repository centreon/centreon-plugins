package Paws::EC2::PropagatingVgw {
  use Moose;
  has GatewayId => (is => 'ro', isa => 'Str', xmlname => 'gatewayId', traits => ['Unwrapped']);
}
1;
