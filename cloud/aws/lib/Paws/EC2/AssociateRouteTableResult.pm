
package Paws::EC2::AssociateRouteTableResult {
  use Moose;
  has AssociationId => (is => 'ro', isa => 'Str', xmlname => 'associationId', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::AssociateRouteTableResult

=head1 ATTRIBUTES

=head2 AssociationId => Str

  

The route table association ID (needed to disassociate the route
table).











=cut

