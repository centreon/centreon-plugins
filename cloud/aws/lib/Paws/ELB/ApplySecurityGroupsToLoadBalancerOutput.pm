
package Paws::ELB::ApplySecurityGroupsToLoadBalancerOutput {
  use Moose;
  has SecurityGroups => (is => 'ro', isa => 'ArrayRef[Str]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ELB::ApplySecurityGroupsToLoadBalancerOutput

=head1 ATTRIBUTES

=head2 SecurityGroups => ArrayRef[Str]

  

The IDs of the security groups associated with the load balancer.











=cut

