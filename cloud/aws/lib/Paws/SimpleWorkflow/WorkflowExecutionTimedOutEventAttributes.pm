package Paws::SimpleWorkflow::WorkflowExecutionTimedOutEventAttributes {
  use Moose;
  has childPolicy => (is => 'ro', isa => 'Str', required => 1);
  has timeoutType => (is => 'ro', isa => 'Str', required => 1);
}
1;
