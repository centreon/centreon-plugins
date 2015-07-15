
package Paws::ELB::DescribeLoadBalancerPolicyTypesOutput {
  use Moose;
  has PolicyTypeDescriptions => (is => 'ro', isa => 'ArrayRef[Paws::ELB::PolicyTypeDescription]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ELB::DescribeLoadBalancerPolicyTypesOutput

=head1 ATTRIBUTES

=head2 PolicyTypeDescriptions => ArrayRef[Paws::ELB::PolicyTypeDescription]

  

Information about the policy types.











=cut

