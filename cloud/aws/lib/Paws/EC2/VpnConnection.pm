package Paws::EC2::VpnConnection {
  use Moose;
  has CustomerGatewayConfiguration => (is => 'ro', isa => 'Str', xmlname => 'customerGatewayConfiguration', traits => ['Unwrapped']);
  has CustomerGatewayId => (is => 'ro', isa => 'Str', xmlname => 'customerGatewayId', traits => ['Unwrapped']);
  has Options => (is => 'ro', isa => 'Paws::EC2::VpnConnectionOptions', xmlname => 'options', traits => ['Unwrapped']);
  has Routes => (is => 'ro', isa => 'ArrayRef[Paws::EC2::VpnStaticRoute]', xmlname => 'routes', traits => ['Unwrapped']);
  has State => (is => 'ro', isa => 'Str', xmlname => 'state', traits => ['Unwrapped']);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', xmlname => 'tagSet', traits => ['Unwrapped']);
  has Type => (is => 'ro', isa => 'Str', xmlname => 'type', traits => ['Unwrapped']);
  has VgwTelemetry => (is => 'ro', isa => 'ArrayRef[Paws::EC2::VgwTelemetry]', xmlname => 'vgwTelemetry', traits => ['Unwrapped']);
  has VpnConnectionId => (is => 'ro', isa => 'Str', xmlname => 'vpnConnectionId', traits => ['Unwrapped']);
  has VpnGatewayId => (is => 'ro', isa => 'Str', xmlname => 'vpnGatewayId', traits => ['Unwrapped']);
}
1;
