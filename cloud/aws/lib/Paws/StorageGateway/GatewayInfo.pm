package Paws::StorageGateway::GatewayInfo {
  use Moose;
  has GatewayARN => (is => 'ro', isa => 'Str');
  has GatewayOperationalState => (is => 'ro', isa => 'Str');
  has GatewayType => (is => 'ro', isa => 'Str');
}
1;
