package Paws::SimpleWorkflow::WorkflowExecutionCompletedEventAttributes {
  use Moose;
  has decisionTaskCompletedEventId => (is => 'ro', isa => 'Int', required => 1);
  has result => (is => 'ro', isa => 'Str');
}
1;
