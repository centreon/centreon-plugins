
package Paws::DataPipeline::ValidatePipelineDefinitionOutput {
  use Moose;
  has errored => (is => 'ro', isa => 'Bool', required => 1);
  has validationErrors => (is => 'ro', isa => 'ArrayRef[Paws::DataPipeline::ValidationError]');
  has validationWarnings => (is => 'ro', isa => 'ArrayRef[Paws::DataPipeline::ValidationWarning]');

}

### main pod documentation begin ###

=head1 NAME

Paws::DataPipeline::ValidatePipelineDefinitionOutput

=head1 ATTRIBUTES

=head2 B<REQUIRED> errored => Bool

  

Indicates whether there were validation errors.









=head2 validationErrors => ArrayRef[Paws::DataPipeline::ValidationError]

  

Any validation errors that were found.









=head2 validationWarnings => ArrayRef[Paws::DataPipeline::ValidationWarning]

  

Any validation warnings that were found.











=cut

1;