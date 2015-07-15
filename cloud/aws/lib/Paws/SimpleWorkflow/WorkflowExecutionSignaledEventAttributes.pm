package Paws::SimpleWorkflow::WorkflowExecutionSignaledEventAttributes {
  use Moose;
  has externalInitiatedEventId => (is => 'ro', isa => 'Int');
  has externalWorkflowExecution => (is => 'ro', isa => 'Paws::SimpleWorkflow::WorkflowExecution');
  has input => (is => 'ro', isa => 'Str');
  has signalName => (is => 'ro', isa => 'Str', required => 1);
}
1;
