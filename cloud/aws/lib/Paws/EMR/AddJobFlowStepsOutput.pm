
package Paws::EMR::AddJobFlowStepsOutput {
  use Moose;
  has StepIds => (is => 'ro', isa => 'ArrayRef[Str]');

}

### main pod documentation begin ###

=head1 NAME

Paws::EMR::AddJobFlowStepsOutput

=head1 ATTRIBUTES

=head2 StepIds => ArrayRef[Str]

  

The identifiers of the list of steps added to the job flow.











=cut

1;