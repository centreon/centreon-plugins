
package Paws::ELB::DetachLoadBalancerFromSubnetsOutput {
  use Moose;
  has Subnets => (is => 'ro', isa => 'ArrayRef[Str]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ELB::DetachLoadBalancerFromSubnetsOutput

=head1 ATTRIBUTES

=head2 Subnets => ArrayRef[Str]

  

The IDs of the remaining subnets for the load balancer.











=cut

