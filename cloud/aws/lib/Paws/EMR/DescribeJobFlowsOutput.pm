
package Paws::EMR::DescribeJobFlowsOutput {
  use Moose;
  has JobFlows => (is => 'ro', isa => 'ArrayRef[Paws::EMR::JobFlowDetail]');

}

### main pod documentation begin ###

=head1 NAME

Paws::EMR::DescribeJobFlowsOutput

=head1 ATTRIBUTES

=head2 JobFlows => ArrayRef[Paws::EMR::JobFlowDetail]

  

A list of job flows matching the parameters supplied.











=cut

1;