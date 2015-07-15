
package Paws::EC2::DescribeReservedInstancesOfferingsResult {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str', xmlname => 'nextToken', traits => ['Unwrapped',]);
  has ReservedInstancesOfferings => (is => 'ro', isa => 'ArrayRef[Paws::EC2::ReservedInstancesOffering]', xmlname => 'reservedInstancesOfferingsSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeReservedInstancesOfferingsResult

=head1 ATTRIBUTES

=head2 NextToken => Str

  

The token to use to retrieve the next page of results. This value is
C<null> when there are no more results to return.









=head2 ReservedInstancesOfferings => ArrayRef[Paws::EC2::ReservedInstancesOffering]

  

A list of Reserved Instances offerings.











=cut

