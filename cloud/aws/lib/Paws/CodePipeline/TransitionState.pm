package Paws::CodePipeline::TransitionState {
  use Moose;
  has disabledReason => (is => 'ro', isa => 'Str');
  has enabled => (is => 'ro', isa => 'Bool');
  has lastChangedAt => (is => 'ro', isa => 'Str');
  has lastChangedBy => (is => 'ro', isa => 'Str');
}
1;
