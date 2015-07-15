
package Paws::EC2::DescribeSpotFleetInstancesResponse {
  use Moose;
  has ActiveInstances => (is => 'ro', isa => 'ArrayRef[Paws::EC2::ActiveInstance]', xmlname => 'activeInstanceSet', traits => ['Unwrapped',], required => 1);
  has NextToken => (is => 'ro', isa => 'Str', xmlname => 'nextToken', traits => ['Unwrapped',]);
  has SpotFleetRequestId => (is => 'ro', isa => 'Str', xmlname => 'spotFleetRequestId', traits => ['Unwrapped',], required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeSpotFleetInstancesResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> ActiveInstances => ArrayRef[Paws::EC2::ActiveInstance]

  

The running instances. Note that this list is refreshed periodically
and might be out of date.









=head2 NextToken => Str

  

The token required to retrieve the next set of results. This value is
C<null> when there are no more results to return.









=head2 B<REQUIRED> SpotFleetRequestId => Str

  

The ID of the Spot fleet request.











=cut

