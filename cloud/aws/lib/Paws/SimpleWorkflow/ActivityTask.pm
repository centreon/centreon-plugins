
package Paws::SimpleWorkflow::ActivityTask {
  use Moose;
  has activityId => (is => 'ro', isa => 'Str', required => 1);
  has activityType => (is => 'ro', isa => 'Paws::SimpleWorkflow::ActivityType', required => 1);
  has input => (is => 'ro', isa => 'Str');
  has startedEventId => (is => 'ro', isa => 'Int', required => 1);
  has taskToken => (is => 'ro', isa => 'Str', required => 1);
  has workflowExecution => (is => 'ro', isa => 'Paws::SimpleWorkflow::WorkflowExecution', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::SimpleWorkflow::ActivityTask

=head1 ATTRIBUTES

=head2 B<REQUIRED> activityId => Str

  

The unique ID of the task.









=head2 B<REQUIRED> activityType => Paws::SimpleWorkflow::ActivityType

  

The type of this activity task.









=head2 input => Str

  

The inputs provided when the activity task was scheduled. The form of
the input is user defined and should be meaningful to the activity
implementation.









=head2 B<REQUIRED> startedEventId => Int

  

The id of the C<ActivityTaskStarted> event recorded in the history.









=head2 B<REQUIRED> taskToken => Str

  

The opaque string used as a handle on the task. This token is used by
workers to communicate progress and response information back to the
system about the task.









=head2 B<REQUIRED> workflowExecution => Paws::SimpleWorkflow::WorkflowExecution

  

The workflow execution that started this activity task.











=cut

1;