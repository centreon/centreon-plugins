
package Paws::EC2::CreateRouteTableResult {
  use Moose;
  has RouteTable => (is => 'ro', isa => 'Paws::EC2::RouteTable', xmlname => 'routeTable', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateRouteTableResult

=head1 ATTRIBUTES

=head2 RouteTable => Paws::EC2::RouteTable

  

Information about the route table.











=cut

