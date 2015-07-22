
package Paws::CodePipeline::PutActionRevisionOutput {
  use Moose;
  has newRevision => (is => 'ro', isa => 'Bool');
  has pipelineExecutionId => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodePipeline::PutActionRevisionOutput

=head1 ATTRIBUTES

=head2 newRevision => Bool

  

The new revision number or ID for the revision after the action
completes.









=head2 pipelineExecutionId => Str

  

The ID of the current workflow state of the pipeline.











=cut

1;