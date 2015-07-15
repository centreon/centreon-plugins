
package Paws::DataPipeline::DescribeObjectsOutput {
  use Moose;
  has hasMoreResults => (is => 'ro', isa => 'Bool');
  has marker => (is => 'ro', isa => 'Str');
  has pipelineObjects => (is => 'ro', isa => 'ArrayRef[Paws::DataPipeline::PipelineObject]', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::DataPipeline::DescribeObjectsOutput

=head1 ATTRIBUTES

=head2 hasMoreResults => Bool

  

Indicates whether there are more results to return.









=head2 marker => Str

  

The starting point for the next page of results. To view the next page
of results, call C<DescribeObjects> again with this marker value. If
the value is null, there are no more results.









=head2 B<REQUIRED> pipelineObjects => ArrayRef[Paws::DataPipeline::PipelineObject]

  

An array of object definitions.











=cut

1;