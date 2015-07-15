package Paws::SimpleWorkflow::WorkflowExecutionCancelRequestedEventAttributes {
  use Moose;
  has cause => (is => 'ro', isa => 'Str');
  has externalInitiatedEventId => (is => 'ro', isa => 'Int');
  has externalWorkflowExecution => (is => 'ro', isa => 'Paws::SimpleWorkflow::WorkflowExecution');
}
1;
