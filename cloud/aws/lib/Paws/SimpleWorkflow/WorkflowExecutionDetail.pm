
package Paws::SimpleWorkflow::WorkflowExecutionDetail {
  use Moose;
  has executionConfiguration => (is => 'ro', isa => 'Paws::SimpleWorkflow::WorkflowExecutionConfiguration', required => 1);
  has executionInfo => (is => 'ro', isa => 'Paws::SimpleWorkflow::WorkflowExecutionInfo', required => 1);
  has latestActivityTaskTimestamp => (is => 'ro', isa => 'Str');
  has latestExecutionContext => (is => 'ro', isa => 'Str');
  has openCounts => (is => 'ro', isa => 'Paws::SimpleWorkflow::WorkflowExecutionOpenCounts', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::SimpleWorkflow::WorkflowExecutionDetail

=head1 ATTRIBUTES

=head2 B<REQUIRED> executionConfiguration => Paws::SimpleWorkflow::WorkflowExecutionConfiguration

  

The configuration settings for this workflow execution including
timeout values, tasklist etc.









=head2 B<REQUIRED> executionInfo => Paws::SimpleWorkflow::WorkflowExecutionInfo

  

Information about the workflow execution.









=head2 latestActivityTaskTimestamp => Str

  

The time when the last activity task was scheduled for this workflow
execution. You can use this information to determine if the workflow
has not made progress for an unusually long period of time and might
require a corrective action.









=head2 latestExecutionContext => Str

  

The latest executionContext provided by the decider for this workflow
execution. A decider can provide an executionContext (a free-form
string) when closing a decision task using
RespondDecisionTaskCompleted.









=head2 B<REQUIRED> openCounts => Paws::SimpleWorkflow::WorkflowExecutionOpenCounts

  

The number of tasks for this workflow execution. This includes open and
closed tasks of all types.











=cut

1;