
package Paws::EC2::PurchaseReservedInstancesOfferingResult {
  use Moose;
  has ReservedInstancesId => (is => 'ro', isa => 'Str', xmlname => 'reservedInstancesId', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::PurchaseReservedInstancesOfferingResult

=head1 ATTRIBUTES

=head2 ReservedInstancesId => Str

  

The IDs of the purchased Reserved Instances.











=cut

