package Paws::SimpleWorkflow::WorkflowExecutionInfo {
  use Moose;
  has cancelRequested => (is => 'ro', isa => 'Bool');
  has closeStatus => (is => 'ro', isa => 'Str');
  has closeTimestamp => (is => 'ro', isa => 'Str');
  has execution => (is => 'ro', isa => 'Paws::SimpleWorkflow::WorkflowExecution', required => 1);
  has executionStatus => (is => 'ro', isa => 'Str', required => 1);
  has parent => (is => 'ro', isa => 'Paws::SimpleWorkflow::WorkflowExecution');
  has startTimestamp => (is => 'ro', isa => 'Str', required => 1);
  has tagList => (is => 'ro', isa => 'ArrayRef[Str]');
  has workflowType => (is => 'ro', isa => 'Paws::SimpleWorkflow::WorkflowType', required => 1);
}
1;
