
package Paws::ELB::DescribeAccessPointsOutput {
  use Moose;
  has LoadBalancerDescriptions => (is => 'ro', isa => 'ArrayRef[Paws::ELB::LoadBalancerDescription]');
  has NextMarker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ELB::DescribeAccessPointsOutput

=head1 ATTRIBUTES

=head2 LoadBalancerDescriptions => ArrayRef[Paws::ELB::LoadBalancerDescription]

  

Information about the load balancers.









=head2 NextMarker => Str

  

The marker to use when requesting the next set of results. If there are
no additional results, the string is empty.











=cut

