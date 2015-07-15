
package Paws::SimpleWorkflow::RegisterWorkflowType {
  use Moose;
  has defaultChildPolicy => (is => 'ro', isa => 'Str');
  has defaultExecutionStartToCloseTimeout => (is => 'ro', isa => 'Str');
  has defaultTaskList => (is => 'ro', isa => 'Paws::SimpleWorkflow::TaskList');
  has defaultTaskPriority => (is => 'ro', isa => 'Str');
  has defaultTaskStartToCloseTimeout => (is => 'ro', isa => 'Str');
  has description => (is => 'ro', isa => 'Str');
  has domain => (is => 'ro', isa => 'Str', required => 1);
  has name => (is => 'ro', isa => 'Str', required => 1);
  has version => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RegisterWorkflowType');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SimpleWorkflow::RegisterWorkflowType - Arguments for method RegisterWorkflowType on Paws::SimpleWorkflow

=head1 DESCRIPTION

This class represents the parameters used for calling the method RegisterWorkflowType on the 
Amazon Simple Workflow Service service. Use the attributes of this class
as arguments to method RegisterWorkflowType.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RegisterWorkflowType.

As an example:

  $service_obj->RegisterWorkflowType(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 defaultChildPolicy => Str

  

If set, specifies the default policy to use for the child workflow
executions when a workflow execution of this type is terminated, by
calling the TerminateWorkflowExecution action explicitly or due to an
expired timeout. This default can be overridden when starting a
workflow execution using the StartWorkflowExecution action or the
C<StartChildWorkflowExecution> Decision.

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










=head2 defaultExecutionStartToCloseTimeout => Str

  

If set, specifies the default maximum duration for executions of this
workflow type. You can override this default when starting an execution
through the StartWorkflowExecution Action or
C<StartChildWorkflowExecution> Decision.

The duration is specified in seconds; an integer greater than or equal
to 0. Unlike some of the other timeout parameters in Amazon SWF, you
cannot specify a value of "NONE" for
C<defaultExecutionStartToCloseTimeout>; there is a one-year max limit
on the time that a workflow execution can run. Exceeding this limit
will always cause the workflow execution to time out.










=head2 defaultTaskList => Paws::SimpleWorkflow::TaskList

  

If set, specifies the default task list to use for scheduling decision
tasks for executions of this workflow type. This default is used only
if a task list is not provided when starting the execution through the
StartWorkflowExecution Action or C<StartChildWorkflowExecution>
Decision.










=head2 defaultTaskPriority => Str

  

The default task priority to assign to the workflow type. If not
assigned, then "0" will be used. Valid values are integers that range
from Java's C<Integer.MIN_VALUE> (-2147483648) to C<Integer.MAX_VALUE>
(2147483647). Higher numbers indicate higher priority.

For more information about setting task priority, see Setting Task
Priority in the I<Amazon Simple Workflow Developer Guide>.










=head2 defaultTaskStartToCloseTimeout => Str

  

If set, specifies the default maximum duration of decision tasks for
this workflow type. This default can be overridden when starting a
workflow execution using the StartWorkflowExecution action or the
C<StartChildWorkflowExecution> Decision.

The duration is specified in seconds; an integer greater than or equal
to 0. The value "NONE" can be used to specify unlimited duration.










=head2 description => Str

  

Textual description of the workflow type.










=head2 B<REQUIRED> domain => Str

  

The name of the domain in which to register the workflow type.










=head2 B<REQUIRED> name => Str

  

The name of the workflow type.

The specified string must not start or end with whitespace. It must not
contain a C<:> (colon), C</> (slash), C<|> (vertical bar), or any
control characters (\u0000-\u001f | \u007f - \u009f). Also, it must not
contain the literal string quotarnquot.










=head2 B<REQUIRED> version => Str

  

The version of the workflow type.

The workflow type consists of the name and version, the combination of
which must be unique within the domain. To get a list of all currently
registered workflow types, use the ListWorkflowTypes action.

The specified string must not start or end with whitespace. It must not
contain a C<:> (colon), C</> (slash), C<|> (vertical bar), or any
control characters (\u0000-\u001f | \u007f - \u009f). Also, it must not
contain the literal string quotarnquot.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RegisterWorkflowType in L<Paws::SimpleWorkflow>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

