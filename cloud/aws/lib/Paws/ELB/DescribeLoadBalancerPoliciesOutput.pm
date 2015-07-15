
package Paws::ELB::DescribeLoadBalancerPoliciesOutput {
  use Moose;
  has PolicyDescriptions => (is => 'ro', isa => 'ArrayRef[Paws::ELB::PolicyDescription]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ELB::DescribeLoadBalancerPoliciesOutput

=head1 ATTRIBUTES

=head2 PolicyDescriptions => ArrayRef[Paws::ELB::PolicyDescription]

  

Information about the policies.











=cut

