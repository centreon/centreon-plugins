
package Paws::SimpleWorkflow::TerminateWorkflowExecution {
  use Moose;
  has childPolicy => (is => 'ro', isa => 'Str');
  has details => (is => 'ro', isa => 'Str');
  has domain => (is => 'ro', isa => 'Str', required => 1);
  has reason => (is => 'ro', isa => 'Str');
  has runId => (is => 'ro', isa => 'Str');
  has workflowId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'TerminateWorkflowExecution');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SimpleWorkflow::TerminateWorkflowExecution - Arguments for method TerminateWorkflowExecution on Paws::SimpleWorkflow

=head1 DESCRIPTION

This class represents the parameters used for calling the method TerminateWorkflowExecution on the 
Amazon Simple Workflow Service service. Use the attributes of this class
as arguments to method TerminateWorkflowExecution.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to TerminateWorkflowExecution.

As an example:

  $service_obj->TerminateWorkflowExecution(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 childPolicy => Str

  

If set, specifies the policy to use for the child workflow executions
of the workflow execution being terminated. This policy overrides the
child policy specified for the workflow execution at registration time
or when starting the execution.

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










=head2 details => Str

  

I<Optional.> Details for terminating the workflow execution.










=head2 B<REQUIRED> domain => Str

  

The domain of the workflow execution to terminate.










=head2 reason => Str

  

I<Optional.> A descriptive reason for terminating the workflow
execution.










=head2 runId => Str

  

The runId of the workflow execution to terminate.










=head2 B<REQUIRED> workflowId => Str

  

The workflowId of the workflow execution to terminate.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method TerminateWorkflowExecution in L<Paws::SimpleWorkflow>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

