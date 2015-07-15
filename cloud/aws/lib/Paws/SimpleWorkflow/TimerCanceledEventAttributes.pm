package Paws::SimpleWorkflow::TimerCanceledEventAttributes {
  use Moose;
  has decisionTaskCompletedEventId => (is => 'ro', isa => 'Int', required => 1);
  has startedEventId => (is => 'ro', isa => 'Int', required => 1);
  has timerId => (is => 'ro', isa => 'Str', required => 1);
}
1;
