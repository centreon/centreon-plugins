
package Paws::SimpleWorkflow::StartWorkflowExecution {
  use Moose;
  has childPolicy => (is => 'ro', isa => 'Str');
  has domain => (is => 'ro', isa => 'Str', required => 1);
  has executionStartToCloseTimeout => (is => 'ro', isa => 'Str');
  has input => (is => 'ro', isa => 'Str');
  has tagList => (is => 'ro', isa => 'ArrayRef[Str]');
  has taskList => (is => 'ro', isa => 'Paws::SimpleWorkflow::TaskList');
  has taskPriority => (is => 'ro', isa => 'Str');
  has taskStartToCloseTimeout => (is => 'ro', isa => 'Str');
  has workflowId => (is => 'ro', isa => 'Str', required => 1);
  has workflowType => (is => 'ro', isa => 'Paws::SimpleWorkflow::WorkflowType', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'StartWorkflowExecution');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SimpleWorkflow::Run');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SimpleWorkflow::StartWorkflowExecution - Arguments for method StartWorkflowExecution on Paws::SimpleWorkflow

=head1 DESCRIPTION

This class represents the parameters used for calling the method StartWorkflowExecution on the 
Amazon Simple Workflow Service service. Use the attributes of this class
as arguments to method StartWorkflowExecution.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to StartWorkflowExecution.

As an example:

  $service_obj->StartWorkflowExecution(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 childPolicy => Str

  

If set, specifies the policy to use for the child workflow executions
of this workflow execution if it is terminated, by calling the
TerminateWorkflowExecution action explicitly or due to an expired
timeout. This policy overrides the default child policy specified when
registering the workflow type using RegisterWorkflowType.

The supported child policies are:

=over

=item * B<TERMINATE:> the child executions will be terminated.

=item * B<REQUEST_CANCEL:> a request to cancel will be attempted for
each child execution by recording a C<WorkflowExecutionCancelRequested>
event in its history. It is up to the decider to take appropriate
actions when it receives an execution history with this event.

=item * B<ABANDON:> no action will be taken. The child executions will
continue to run.

=back

A child policy for this workflow execution must be specified either as
a default for the workflow type or through this parameter. If neither
this parameter is set nor a default child policy was specified at
registration time then a fault will be returned.










=head2 B<REQUIRED> domain => Str

  

The name of the domain in which the workflow execution is created.










=head2 executionStartToCloseTimeout => Str

  

The total duration for this workflow execution. This overrides the
defaultExecutionStartToCloseTimeout specified when registering the
workflow type.

The duration is specified in seconds; an integer greater than or equal
to 0. Exceeding this limit will cause the workflow execution to time
out. Unlike some of the other timeout parameters in Amazon SWF, you
cannot specify a value of "NONE" for this timeout; there is a one-year
max limit on the time that a workflow execution can run.

An execution start-to-close timeout must be specified either through
this parameter or as a default when the workflow type is registered. If
neither this parameter nor a default execution start-to-close timeout
is specified, a fault is returned.










=head2 input => Str

  

The input for the workflow execution. This is a free form string which
should be meaningful to the workflow you are starting. This C<input> is
made available to the new workflow execution in the
C<WorkflowExecutionStarted> history event.










=head2 tagList => ArrayRef[Str]

  

The list of tags to associate with the workflow execution. You can
specify a maximum of 5 tags. You can list workflow executions with a
specific tag by calling ListOpenWorkflowExecutions or
ListClosedWorkflowExecutions and specifying a TagFilter.










=head2 taskList => Paws::SimpleWorkflow::TaskList

  

The task list to use for the decision tasks generated for this workflow
execution. This overrides the C<defaultTaskList> specified when
registering the workflow type.

A task list for this workflow execution must be specified either as a
default for the workflow type or through this parameter. If neither
this parameter is set nor a default task list was specified at
registration time then a fault will be returned.

The specified string must not start or end with whitespace. It must not
contain a C<:> (colon), C</> (slash), C<|> (vertical bar), or any
control characters (\u0000-\u001f | \u007f - \u009f). Also, it must not
contain the literal string quotarnquot.










=head2 taskPriority => Str

  

The task priority to use for this workflow execution. This will
override any default priority that was assigned when the workflow type
was registered. If not set, then the default task priority for the
workflow type will be used. Valid values are integers that range from
Java's C<Integer.MIN_VALUE> (-2147483648) to C<Integer.MAX_VALUE>
(2147483647). Higher numbers indicate higher priority.

For more information about setting task priority, see Setting Task
Priority in the I<Amazon Simple Workflow Developer Guide>.










=head2 taskStartToCloseTimeout => Str

  

Specifies the maximum duration of decision tasks for this workflow
execution. This parameter overrides the
C<defaultTaskStartToCloseTimout> specified when registering the
workflow type using RegisterWorkflowType.

The duration is specified in seconds; an integer greater than or equal
to 0. The value "NONE" can be used to specify unlimited duration.

A task start-to-close timeout for this workflow execution must be
specified either as a default for the workflow type or through this
parameter. If neither this parameter is set nor a default task
start-to-close timeout was specified at registration time then a fault
will be returned.










=head2 B<REQUIRED> workflowId => Str

  

The user defined identifier associated with the workflow execution. You
can use this to associate a custom identifier with the workflow
execution. You may specify the same identifier if a workflow execution
is logically a I<restart> of a previous execution. You cannot have two
open workflow executions with the same C<workflowId> at the same time.

The specified string must not start or end with whitespace. It must not
contain a C<:> (colon), C</> (slash), C<|> (vertical bar), or any
control characters (\u0000-\u001f | \u007f - \u009f). Also, it must not
contain the literal string quotarnquot.










=head2 B<REQUIRED> workflowType => Paws::SimpleWorkflow::WorkflowType

  

The type of the workflow to start.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method StartWorkflowExecution in L<Paws::SimpleWorkflow>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

