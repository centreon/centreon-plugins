
package Paws::DataPipeline::ListPipelinesOutput {
  use Moose;
  has hasMoreResults => (is => 'ro', isa => 'Bool');
  has marker => (is => 'ro', isa => 'Str');
  has pipelineIdList => (is => 'ro', isa => 'ArrayRef[Paws::DataPipeline::PipelineIdName]', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::DataPipeline::ListPipelinesOutput

=head1 ATTRIBUTES

=head2 hasMoreResults => Bool

  

Indicates whether there are more results that can be obtained by a
subsequent call.









=head2 marker => Str

  

The starting point for the next page of results. To view the next page
of results, call C<ListPipelinesOutput> again with this marker value.
If the value is null, there are no more results.









=head2 B<REQUIRED> pipelineIdList => ArrayRef[Paws::DataPipeline::PipelineIdName]

  

The pipeline identifiers. If you require additional information about
the pipelines, you can use these identifiers to call DescribePipelines
and GetPipelineDefinition.











=cut

1;