
package Paws::DataPipeline::DescribePipelinesOutput {
  use Moose;
  has pipelineDescriptionList => (is => 'ro', isa => 'ArrayRef[Paws::DataPipeline::PipelineDescription]', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::DataPipeline::DescribePipelinesOutput

=head1 ATTRIBUTES

=head2 B<REQUIRED> pipelineDescriptionList => ArrayRef[Paws::DataPipeline::PipelineDescription]

  

An array of descriptions for the specified pipelines.











=cut

1;