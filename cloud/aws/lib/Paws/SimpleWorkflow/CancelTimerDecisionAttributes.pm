package Paws::SimpleWorkflow::CancelTimerDecisionAttributes {
  use Moose;
  has timerId => (is => 'ro', isa => 'Str', required => 1);
}
1;
