
package Paws::DataPipeline::GetPipelineDefinitionOutput {
  use Moose;
  has parameterObjects => (is => 'ro', isa => 'ArrayRef[Paws::DataPipeline::ParameterObject]');
  has parameterValues => (is => 'ro', isa => 'ArrayRef[Paws::DataPipeline::ParameterValue]');
  has pipelineObjects => (is => 'ro', isa => 'ArrayRef[Paws::DataPipeline::PipelineObject]');

}

### main pod documentation begin ###

=head1 NAME

Paws::DataPipeline::GetPipelineDefinitionOutput

=head1 ATTRIBUTES

=head2 parameterObjects => ArrayRef[Paws::DataPipeline::ParameterObject]

  

The parameter objects used in the pipeline definition.









=head2 parameterValues => ArrayRef[Paws::DataPipeline::ParameterValue]

  

The parameter values used in the pipeline definition.









=head2 pipelineObjects => ArrayRef[Paws::DataPipeline::PipelineObject]

  

The objects defined in the pipeline.











=cut

1;