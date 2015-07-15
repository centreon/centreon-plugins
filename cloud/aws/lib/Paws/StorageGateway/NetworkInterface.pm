package Paws::StorageGateway::NetworkInterface {
  use Moose;
  has Ipv4Address => (is => 'ro', isa => 'Str');
  has Ipv6Address => (is => 'ro', isa => 'Str');
  has MacAddress => (is => 'ro', isa => 'Str');
}
1;
