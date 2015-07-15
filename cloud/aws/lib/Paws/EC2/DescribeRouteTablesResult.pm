
package Paws::EC2::DescribeRouteTablesResult {
  use Moose;
  has RouteTables => (is => 'ro', isa => 'ArrayRef[Paws::EC2::RouteTable]', xmlname => 'routeTableSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeRouteTablesResult

=head1 ATTRIBUTES

=head2 RouteTables => ArrayRef[Paws::EC2::RouteTable]

  

Information about one or more route tables.











=cut

