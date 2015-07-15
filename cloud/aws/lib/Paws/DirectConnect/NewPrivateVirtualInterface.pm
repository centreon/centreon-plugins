package Paws::DirectConnect::NewPrivateVirtualInterface {
  use Moose;
  has amazonAddress => (is => 'ro', isa => 'Str');
  has asn => (is => 'ro', isa => 'Int', required => 1);
  has authKey => (is => 'ro', isa => 'Str');
  has customerAddress => (is => 'ro', isa => 'Str');
  has virtualGatewayId => (is => 'ro', isa => 'Str', required => 1);
  has virtualInterfaceName => (is => 'ro', isa => 'Str', required => 1);
  has vlan => (is => 'ro', isa => 'Int', required => 1);
}
1;
