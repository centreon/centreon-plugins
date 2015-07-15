
package Paws::SimpleWorkflow::ListClosedWorkflowExecutions {
  use Moose;
  has closeStatusFilter => (is => 'ro', isa => 'Paws::SimpleWorkflow::CloseStatusFilter');
  has closeTimeFilter => (is => 'ro', isa => 'Paws::SimpleWorkflow::ExecutionTimeFilter');
  has domain => (is => 'ro', isa => 'Str', required => 1);
  has executionFilter => (is => 'ro', isa => 'Paws::SimpleWorkflow::WorkflowExecutionFilter');
  has maximumPageSize => (is => 'ro', isa => 'Int');
  has nextPageToken => (is => 'ro', isa => 'Str');
  has reverseOrder => (is => 'ro', isa => 'Bool');
  has startTimeFilter => (is => 'ro', isa => 'Paws::SimpleWorkflow::ExecutionTimeFilter');
  has tagFilter => (is => 'ro', isa => 'Paws::SimpleWorkflow::TagFilter');
  has typeFilter => (is => 'ro', isa => 'Paws::SimpleWorkflow::WorkflowTypeFilter');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListClosedWorkflowExecutions');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SimpleWorkflow::WorkflowExecutionInfos');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SimpleWorkflow::ListClosedWorkflowExecutions - Arguments for method ListClosedWorkflowExecutions on Paws::SimpleWorkflow

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListClosedWorkflowExecutions on the 
Amazon Simple Workflow Service service. Use the attributes of this class
as arguments to method ListClosedWorkflowExecutions.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListClosedWorkflowExecutions.

As an example:

  $service_obj->ListClosedWorkflowExecutions(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 closeStatusFilter => Paws::SimpleWorkflow::CloseStatusFilter

  

If specified, only workflow executions that match this I<close status>
are listed. For example, if TERMINATED is specified, then only
TERMINATED workflow executions are listed.

C<closeStatusFilter>, C<executionFilter>, C<typeFilter> and
C<tagFilter> are mutually exclusive. You can specify at most one of
these in a request.










=head2 closeTimeFilter => Paws::SimpleWorkflow::ExecutionTimeFilter

  

If specified, the workflow executions are included in the returned
results based on whether their close times are within the range
specified by this filter. Also, if this parameter is specified, the
returned results are ordered by their close times.

C<startTimeFilter> and C<closeTimeFilter> are mutually exclusive. You
must specify one of these in a request but not both.










=head2 B<REQUIRED> domain => Str

  

The name of the domain that contains the workflow executions to list.










=head2 executionFilter => Paws::SimpleWorkflow::WorkflowExecutionFilter

  

If specified, only workflow executions matching the workflow id
specified in the filter are returned.

C<closeStatusFilter>, C<executionFilter>, C<typeFilter> and
C<tagFilter> are mutually exclusive. You can specify at most one of
these in a request.










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










=head2 reverseOrder => Bool

  

When set to C<true>, returns the results in reverse order. By default
the results are returned in descending order of the start or the close
time of the executions.










=head2 startTimeFilter => Paws::SimpleWorkflow::ExecutionTimeFilter

  

If specified, the workflow executions are included in the returned
results based on whether their start times are within the range
specified by this filter. Also, if this parameter is specified, the
returned results are ordered by their start times.

C<startTimeFilter> and C<closeTimeFilter> are mutually exclusive. You
must specify one of these in a request but not both.










=head2 tagFilter => Paws::SimpleWorkflow::TagFilter

  

If specified, only executions that have the matching tag are listed.

C<closeStatusFilter>, C<executionFilter>, C<typeFilter> and
C<tagFilter> are mutually exclusive. You can specify at most one of
these in a request.










=head2 typeFilter => Paws::SimpleWorkflow::WorkflowTypeFilter

  

If specified, only executions of the type specified in the filter are
returned.

C<closeStatusFilter>, C<executionFilter>, C<typeFilter> and
C<tagFilter> are mutually exclusive. You can specify at most one of
these in a request.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListClosedWorkflowExecutions in L<Paws::SimpleWorkflow>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

