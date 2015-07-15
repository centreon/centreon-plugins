
package Paws::ELB::AttachLoadBalancerToSubnetsOutput {
  use Moose;
  has Subnets => (is => 'ro', isa => 'ArrayRef[Str]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ELB::AttachLoadBalancerToSubnetsOutput

=head1 ATTRIBUTES

=head2 Subnets => ArrayRef[Str]

  

The IDs of the subnets attached to the load balancer.











=cut

