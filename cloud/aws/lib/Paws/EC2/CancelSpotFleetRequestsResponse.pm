
package Paws::EC2::CancelSpotFleetRequestsResponse {
  use Moose;
  has SuccessfulFleetRequests => (is => 'ro', isa => 'ArrayRef[Paws::EC2::CancelSpotFleetRequestsSuccessItem]', xmlname => 'successfulFleetRequestSet', traits => ['Unwrapped',]);
  has UnsuccessfulFleetRequests => (is => 'ro', isa => 'ArrayRef[Paws::EC2::CancelSpotFleetRequestsErrorItem]', xmlname => 'unsuccessfulFleetRequestSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CancelSpotFleetRequestsResponse

=head1 ATTRIBUTES

=head2 SuccessfulFleetRequests => ArrayRef[Paws::EC2::CancelSpotFleetRequestsSuccessItem]

  

Information about the Spot fleet requests that are successfully
canceled.









=head2 UnsuccessfulFleetRequests => ArrayRef[Paws::EC2::CancelSpotFleetRequestsErrorItem]

  

Information about the Spot fleet requests that are not successfully
canceled.











=cut

