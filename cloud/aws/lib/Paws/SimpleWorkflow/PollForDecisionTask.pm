
package Paws::SimpleWorkflow::PollForDecisionTask {
  use Moose;
  has domain => (is => 'ro', isa => 'Str', required => 1);
  has identity => (is => 'ro', isa => 'Str');
  has maximumPageSize => (is => 'ro', isa => 'Int');
  has nextPageToken => (is => 'ro', isa => 'Str');
  has reverseOrder => (is => 'ro', isa => 'Bool');
  has taskList => (is => 'ro', isa => 'Paws::SimpleWorkflow::TaskList', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PollForDecisionTask');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SimpleWorkflow::DecisionTask');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SimpleWorkflow::PollForDecisionTask - Arguments for method PollForDecisionTask on Paws::SimpleWorkflow

=head1 DESCRIPTION

This class represents the parameters used for calling the method PollForDecisionTask on the 
Amazon Simple Workflow Service service. Use the attributes of this class
as arguments to method PollForDecisionTask.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PollForDecisionTask.

As an example:

  $service_obj->PollForDecisionTask(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> domain => Str

  

The name of the domain containing the task lists to poll.










=head2 identity => Str

  

Identity of the decider making the request, which is recorded in the
DecisionTaskStarted event in the workflow history. This enables
diagnostic tracing when problems arise. The form of this identity is
user defined.










=head2 maximumPageSize => Int

  

The maximum number of results that will be returned per call.
C<nextPageToken> can be used to obtain futher pages of results. The
default is 100, which is the maximum allowed page size. You can,
however, specify a page size I<smaller> than 100.

This is an upper limit only; the actual number of results returned per
call may be fewer than the specified maximum.










=head2 nextPageToken => Str

  

If a C<NextPageToken> was returned by a previous call, there are more
results available. To retrieve the next page of results, make the call
again using the returned token in C<nextPageToken>. Keep all other
arguments unchanged.

The configured C<maximumPageSize> determines how many results can be
returned in a single call.

The C<nextPageToken> returned by this action cannot be used with
GetWorkflowExecutionHistory to get the next page. You must call
PollForDecisionTask again (with the C<nextPageToken>) to retrieve the
next page of history records. Calling PollForDecisionTask with a
C<nextPageToken> will not return a new decision task..










=head2 reverseOrder => Bool

  

When set to C<true>, returns the events in reverse order. By default
the results are returned in ascending order of the C<eventTimestamp> of
the events.










=head2 B<REQUIRED> taskList => Paws::SimpleWorkflow::TaskList

  

Specifies the task list to poll for decision tasks.

The specified string must not start or end with whitespace. It must not
contain a C<:> (colon), C</> (slash), C<|> (vertical bar), or any
control characters (\u0000-\u001f | \u007f - \u009f). Also, it must not
contain the literal string quotarnquot.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PollForDecisionTask in L<Paws::SimpleWorkflow>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

