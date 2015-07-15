package Paws::SimpleWorkflow::RequestCancelExternalWorkflowExecutionInitiatedEventAttributes {
  use Moose;
  has control => (is => 'ro', isa => 'Str');
  has decisionTaskCompletedEventId => (is => 'ro', isa => 'Int', required => 1);
  has runId => (is => 'ro', isa => 'Str');
  has workflowId => (is => 'ro', isa => 'Str', required => 1);
}
1;
