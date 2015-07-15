
package Paws::AutoScaling::DescribeLoadBalancersResponse {
  use Moose;
  has LoadBalancers => (is => 'ro', isa => 'ArrayRef[Paws::AutoScaling::LoadBalancerState]');
  has NextToken => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::DescribeLoadBalancersResponse

=head1 ATTRIBUTES

=head2 LoadBalancers => ArrayRef[Paws::AutoScaling::LoadBalancerState]

  

The load balancers.









=head2 NextToken => Str

  

The token to use when requesting the next set of items. If there are no
additional items to return, the string is empty.











=cut

