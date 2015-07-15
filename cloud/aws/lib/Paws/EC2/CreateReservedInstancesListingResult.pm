
package Paws::EC2::CreateReservedInstancesListingResult {
  use Moose;
  has ReservedInstancesListings => (is => 'ro', isa => 'ArrayRef[Paws::EC2::ReservedInstancesListing]', xmlname => 'reservedInstancesListingsSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateReservedInstancesListingResult

=head1 ATTRIBUTES

=head2 ReservedInstancesListings => ArrayRef[Paws::EC2::ReservedInstancesListing]

  

Information about the Reserved Instances listing.











=cut

