
package Paws::EC2::DescribeMovingAddressesResult {
  use Moose;
  has MovingAddressStatuses => (is => 'ro', isa => 'ArrayRef[Paws::EC2::MovingAddressStatus]', xmlname => 'movingAddressStatusSet', traits => ['Unwrapped',]);
  has NextToken => (is => 'ro', isa => 'Str', xmlname => 'nextToken', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeMovingAddressesResult

=head1 ATTRIBUTES

=head2 MovingAddressStatuses => ArrayRef[Paws::EC2::MovingAddressStatus]

  

The status for each Elastic IP address.









=head2 NextToken => Str

  

The token to use to retrieve the next page of results. This value is
C<null> when there are no more results to return.











=cut

