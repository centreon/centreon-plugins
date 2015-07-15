package Paws::SimpleWorkflow::FailWorkflowExecutionDecisionAttributes {
  use Moose;
  has details => (is => 'ro', isa => 'Str');
  has reason => (is => 'ro', isa => 'Str');
}
1;
