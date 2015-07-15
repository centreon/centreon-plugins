package Paws::SimpleWorkflow::WorkflowExecution {
  use Moose;
  has runId => (is => 'ro', isa => 'Str', required => 1);
  has workflowId => (is => 'ro', isa => 'Str', required => 1);
}
1;
