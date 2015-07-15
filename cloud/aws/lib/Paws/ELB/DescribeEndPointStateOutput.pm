
package Paws::ELB::DescribeEndPointStateOutput {
  use Moose;
  has InstanceStates => (is => 'ro', isa => 'ArrayRef[Paws::ELB::InstanceState]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ELB::DescribeEndPointStateOutput

=head1 ATTRIBUTES

=head2 InstanceStates => ArrayRef[Paws::ELB::InstanceState]

  

Information about the health of the instances.











=cut

