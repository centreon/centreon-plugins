package Paws::SimpleWorkflow::WorkflowTypeConfiguration {
  use Moose;
  has defaultChildPolicy => (is => 'ro', isa => 'Str');
  has defaultExecutionStartToCloseTimeout => (is => 'ro', isa => 'Str');
  has defaultTaskList => (is => 'ro', isa => 'Paws::SimpleWorkflow::TaskList');
  has defaultTaskPriority => (is => 'ro', isa => 'Str');
  has defaultTaskStartToCloseTimeout => (is => 'ro', isa => 'Str');
}
1;
