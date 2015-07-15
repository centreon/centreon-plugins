package Paws::SimpleWorkflow::WorkflowExecutionFailedEventAttributes {
  use Moose;
  has decisionTaskCompletedEventId => (is => 'ro', isa => 'Int', required => 1);
  has details => (is => 'ro', isa => 'Str');
  has reason => (is => 'ro', isa => 'Str');
}
1;
