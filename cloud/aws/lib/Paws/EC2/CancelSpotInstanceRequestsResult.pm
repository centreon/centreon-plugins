
package Paws::EC2::CancelSpotInstanceRequestsResult {
  use Moose;
  has CancelledSpotInstanceRequests => (is => 'ro', isa => 'ArrayRef[Paws::EC2::CancelledSpotInstanceRequest]', xmlname => 'spotInstanceRequestSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CancelSpotInstanceRequestsResult

=head1 ATTRIBUTES

=head2 CancelledSpotInstanceRequests => ArrayRef[Paws::EC2::CancelledSpotInstanceRequest]

  

One or more Spot Instance requests.











=cut

