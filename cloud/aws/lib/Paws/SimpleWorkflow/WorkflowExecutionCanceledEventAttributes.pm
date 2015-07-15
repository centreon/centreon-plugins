package Paws::SimpleWorkflow::WorkflowExecutionCanceledEventAttributes {
  use Moose;
  has decisionTaskCompletedEventId => (is => 'ro', isa => 'Int', required => 1);
  has details => (is => 'ro', isa => 'Str');
}
1;
