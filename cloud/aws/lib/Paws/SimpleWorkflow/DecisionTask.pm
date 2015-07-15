
package Paws::SimpleWorkflow::DecisionTask {
  use Moose;
  has events => (is => 'ro', isa => 'ArrayRef[Paws::SimpleWorkflow::HistoryEvent]', required => 1);
  has nextPageToken => (is => 'ro', isa => 'Str');
  has previousStartedEventId => (is => 'ro', isa => 'Int');
  has startedEventId => (is => 'ro', isa => 'Int', required => 1);
  has taskToken => (is => 'ro', isa => 'Str', required => 1);
  has workflowExecution => (is => 'ro', isa => 'Paws::SimpleWorkflow::WorkflowExecution', required => 1);
  has workflowType => (is => 'ro', isa => 'Paws::SimpleWorkflow::WorkflowType', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::SimpleWorkflow::DecisionTask

=head1 ATTRIBUTES

=head2 B<REQUIRED> events => ArrayRef[Paws::SimpleWorkflow::HistoryEvent]

  

A paginated list of history events of the workflow execution. The
decider uses this during the processing of the decision task.









=head2 nextPageToken => Str

  

If a C<NextPageToken> was returned by a previous call, there are more
results available. To retrieve the next page of results, make the call
again using the returned token in C<nextPageToken>. Keep all other
arguments unchanged.

The configured C<maximumPageSize> determines how many results can be
returned in a single call.









=head2 previousStartedEventId => Int

  

The id of the DecisionTaskStarted event of the previous decision task
of this workflow execution that was processed by the decider. This can
be used to determine the events in the history new since the last
decision task received by the decider.









=head2 B<REQUIRED> startedEventId => Int

  

The id of the C<DecisionTaskStarted> event recorded in the history.









=head2 B<REQUIRED> taskToken => Str

  

The opaque string used as a handle on the task. This token is used by
workers to communicate progress and response information back to the
system about the task.









=head2 B<REQUIRED> workflowExecution => Paws::SimpleWorkflow::WorkflowExecution

  

The workflow execution for which this decision task was created.









=head2 B<REQUIRED> workflowType => Paws::SimpleWorkflow::WorkflowType

  

The type of the workflow execution for which this decision task was
created.











=cut

1;