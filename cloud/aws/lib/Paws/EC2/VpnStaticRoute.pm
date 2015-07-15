package Paws::EC2::VpnStaticRoute {
  use Moose;
  has DestinationCidrBlock => (is => 'ro', isa => 'Str', xmlname => 'destinationCidrBlock', traits => ['Unwrapped']);
  has Source => (is => 'ro', isa => 'Str', xmlname => 'source', traits => ['Unwrapped']);
  has State => (is => 'ro', isa => 'Str', xmlname => 'state', traits => ['Unwrapped']);
}
1;
