
package Paws::DirectConnect::VirtualInterface {
  use Moose;
  has amazonAddress => (is => 'ro', isa => 'Str');
  has asn => (is => 'ro', isa => 'Int');
  has authKey => (is => 'ro', isa => 'Str');
  has connectionId => (is => 'ro', isa => 'Str');
  has customerAddress => (is => 'ro', isa => 'Str');
  has customerRouterConfig => (is => 'ro', isa => 'Str');
  has location => (is => 'ro', isa => 'Str');
  has ownerAccount => (is => 'ro', isa => 'Str');
  has routeFilterPrefixes => (is => 'ro', isa => 'ArrayRef[Paws::DirectConnect::RouteFilterPrefix]');
  has virtualGatewayId => (is => 'ro', isa => 'Str');
  has virtualInterfaceId => (is => 'ro', isa => 'Str');
  has virtualInterfaceName => (is => 'ro', isa => 'Str');
  has virtualInterfaceState => (is => 'ro', isa => 'Str');
  has virtualInterfaceType => (is => 'ro', isa => 'Str');
  has vlan => (is => 'ro', isa => 'Int');

}

### main pod documentation begin ###

=head1 NAME

Paws::DirectConnect::VirtualInterface

=head1 ATTRIBUTES

=head2 amazonAddress => Str

  
=head2 asn => Int

  
=head2 authKey => Str

  
=head2 connectionId => Str

  
=head2 customerAddress => Str

  
=head2 customerRouterConfig => Str

  

Information for generating the customer router configuration.









=head2 location => Str

  
=head2 ownerAccount => Str

  
=head2 routeFilterPrefixes => ArrayRef[Paws::DirectConnect::RouteFilterPrefix]

  
=head2 virtualGatewayId => Str

  
=head2 virtualInterfaceId => Str

  
=head2 virtualInterfaceName => Str

  
=head2 virtualInterfaceState => Str

  
=head2 virtualInterfaceType => Str

  
=head2 vlan => Int

  


=cut

1;