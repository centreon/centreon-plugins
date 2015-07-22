package Paws::CodePipeline::ActionState {
  use Moose;
  has actionName => (is => 'ro', isa => 'Str');
  has currentRevision => (is => 'ro', isa => 'Paws::CodePipeline::ActionRevision');
  has entityUrl => (is => 'ro', isa => 'Str');
  has latestExecution => (is => 'ro', isa => 'Paws::CodePipeline::ActionExecution');
  has revisionUrl => (is => 'ro', isa => 'Str');
}
1;
