
package Paws::CodePipeline::GetPipelineStateOutput {
  use Moose;
  has created => (is => 'ro', isa => 'Str');
  has pipelineName => (is => 'ro', isa => 'Str');
  has pipelineVersion => (is => 'ro', isa => 'Int');
  has stageStates => (is => 'ro', isa => 'ArrayRef[Paws::CodePipeline::StageState]');
  has updated => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodePipeline::GetPipelineStateOutput

=head1 ATTRIBUTES

=head2 created => Str

  

The date and time the pipeline was created, in timestamp format.









=head2 pipelineName => Str

  

The name of the pipeline for which you want to get the state.









=head2 pipelineVersion => Int

  

The version number of the pipeline.

A newly-created pipeline is always assigned a version number of C<1>.









=head2 stageStates => ArrayRef[Paws::CodePipeline::StageState]

  

A list of the pipeline stage output information, including stage name,
state, most recent run details, whether the stage is disabled, and
other data.









=head2 updated => Str

  

The date and time the pipeline was last updated, in timestamp format.











=cut

1;