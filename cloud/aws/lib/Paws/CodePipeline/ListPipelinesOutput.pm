
package Paws::CodePipeline::ListPipelinesOutput {
  use Moose;
  has nextToken => (is => 'ro', isa => 'Str');
  has pipelines => (is => 'ro', isa => 'ArrayRef[Paws::CodePipeline::PipelineSummary]');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodePipeline::ListPipelinesOutput

=head1 ATTRIBUTES

=head2 nextToken => Str

  

If the amount of returned information is significantly large, an
identifier is also returned which can be used in a subsequent list
pipelines call to return the next set of pipelines in the list.









=head2 pipelines => ArrayRef[Paws::CodePipeline::PipelineSummary]

  

The list of pipelines.











=cut

1;