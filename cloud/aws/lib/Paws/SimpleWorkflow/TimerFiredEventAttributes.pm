package Paws::SimpleWorkflow::TimerFiredEventAttributes {
  use Moose;
  has startedEventId => (is => 'ro', isa => 'Int', required => 1);
  has timerId => (is => 'ro', isa => 'Str', required => 1);
}
1;
