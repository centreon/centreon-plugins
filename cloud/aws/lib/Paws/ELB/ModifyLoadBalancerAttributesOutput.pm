
package Paws::ELB::ModifyLoadBalancerAttributesOutput {
  use Moose;
  has LoadBalancerAttributes => (is => 'ro', isa => 'Paws::ELB::LoadBalancerAttributes');
  has LoadBalancerName => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ELB::ModifyLoadBalancerAttributesOutput

=head1 ATTRIBUTES

=head2 LoadBalancerAttributes => Paws::ELB::LoadBalancerAttributes

  
=head2 LoadBalancerName => Str

  

The name of the load balancer.











=cut

