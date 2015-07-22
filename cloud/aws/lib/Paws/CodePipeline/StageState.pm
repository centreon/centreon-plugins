package Paws::CodePipeline::StageState {
  use Moose;
  has actionStates => (is => 'ro', isa => 'ArrayRef[Paws::CodePipeline::ActionState]');
  has inboundTransitionState => (is => 'ro', isa => 'Paws::CodePipeline::TransitionState');
  has stageName => (is => 'ro', isa => 'Str');
}
1;
