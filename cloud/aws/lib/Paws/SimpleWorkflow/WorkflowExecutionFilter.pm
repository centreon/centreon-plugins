package Paws::SimpleWorkflow::WorkflowExecutionFilter {
  use Moose;
  has workflowId => (is => 'ro', isa => 'Str', required => 1);
}
1;
