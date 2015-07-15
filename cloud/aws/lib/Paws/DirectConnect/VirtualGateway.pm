package Paws::DirectConnect::VirtualGateway {
  use Moose;
  has virtualGatewayId => (is => 'ro', isa => 'Str');
  has virtualGatewayState => (is => 'ro', isa => 'Str');
}
1;
