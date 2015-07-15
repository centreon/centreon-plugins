
package Paws::DataPipeline::PutPipelineDefinitionOutput {
  use Moose;
  has errored => (is => 'ro', isa => 'Bool', required => 1);
  has validationErrors => (is => 'ro', isa => 'ArrayRef[Paws::DataPipeline::ValidationError]');
  has validationWarnings => (is => 'ro', isa => 'ArrayRef[Paws::DataPipeline::ValidationWarning]');

}

### main pod documentation begin ###

=head1 NAME

Paws::DataPipeline::PutPipelineDefinitionOutput

=head1 ATTRIBUTES

=head2 B<REQUIRED> errored => Bool

  

Indicates whether there were validation errors, and the pipeline
definition is stored but cannot be activated until you correct the
pipeline and call C<PutPipelineDefinition> to commit the corrected
pipeline.









=head2 validationErrors => ArrayRef[Paws::DataPipeline::ValidationError]

  

The validation errors that are associated with the objects defined in
C<pipelineObjects>.









=head2 validationWarnings => ArrayRef[Paws::DataPipeline::ValidationWarning]

  

The validation warnings that are associated with the objects defined in
C<pipelineObjects>.











=cut

1;