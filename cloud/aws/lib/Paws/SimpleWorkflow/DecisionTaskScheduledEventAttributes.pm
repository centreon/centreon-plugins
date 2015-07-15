package Paws::SimpleWorkflow::DecisionTaskScheduledEventAttributes {
  use Moose;
  has startToCloseTimeout => (is => 'ro', isa => 'Str');
  has taskList => (is => 'ro', isa => 'Paws::SimpleWorkflow::TaskList', required => 1);
  has taskPriority => (is => 'ro', isa => 'Str');
}
1;
