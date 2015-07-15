package Paws::EC2::CustomerGateway {
  use Moose;
  has BgpAsn => (is => 'ro', isa => 'Str', xmlname => 'bgpAsn', traits => ['Unwrapped']);
  has CustomerGatewayId => (is => 'ro', isa => 'Str', xmlname => 'customerGatewayId', traits => ['Unwrapped']);
  has IpAddress => (is => 'ro', isa => 'Str', xmlname => 'ipAddress', traits => ['Unwrapped']);
  has State => (is => 'ro', isa => 'Str', xmlname => 'state', traits => ['Unwrapped']);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', xmlname => 'tagSet', traits => ['Unwrapped']);
  has Type => (is => 'ro', isa => 'Str', xmlname => 'type', traits => ['Unwrapped']);
}
1;
