
package Paws::EC2::ModifyReservedInstancesResult {
  use Moose;
  has ReservedInstancesModificationId => (is => 'ro', isa => 'Str', xmlname => 'reservedInstancesModificationId', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::ModifyReservedInstancesResult

=head1 ATTRIBUTES

=head2 ReservedInstancesModificationId => Str

  

The ID for the modification.











=cut

