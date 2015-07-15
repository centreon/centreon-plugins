
package Paws::EC2::ReplaceRouteTableAssociationResult {
  use Moose;
  has NewAssociationId => (is => 'ro', isa => 'Str', xmlname => 'newAssociationId', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::ReplaceRouteTableAssociationResult

=head1 ATTRIBUTES

=head2 NewAssociationId => Str

  

The ID of the new association.











=cut

