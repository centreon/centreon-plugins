package Paws::DirectConnect::NewPublicVirtualInterface {
  use Moose;
  has amazonAddress => (is => 'ro', isa => 'Str', required => 1);
  has asn => (is => 'ro', isa => 'Int', required => 1);
  has authKey => (is => 'ro', isa => 'Str');
  has customerAddress => (is => 'ro', isa => 'Str', required => 1);
  has routeFilterPrefixes => (is => 'ro', isa => 'ArrayRef[Paws::DirectConnect::RouteFilterPrefix]', required => 1);
  has virtualInterfaceName => (is => 'ro', isa => 'Str', required => 1);
  has vlan => (is => 'ro', isa => 'Int', required => 1);
}
1;
