
package Paws::EC2::DescribeSpotInstanceRequestsResult {
  use Moose;
  has SpotInstanceRequests => (is => 'ro', isa => 'ArrayRef[Paws::EC2::SpotInstanceRequest]', xmlname => 'spotInstanceRequestSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeSpotInstanceRequestsResult

=head1 ATTRIBUTES

=head2 SpotInstanceRequests => ArrayRef[Paws::EC2::SpotInstanceRequest]

  

One or more Spot Instance requests.











=cut

