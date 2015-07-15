
package Paws::SimpleWorkflow::SignalWorkflowExecution {
  use Moose;
  has domain => (is => 'ro', isa => 'Str', required => 1);
  has input => (is => 'ro', isa => 'Str');
  has runId => (is => 'ro', isa => 'Str');
  has signalName => (is => 'ro', isa => 'Str', required => 1);
  has workflowId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'SignalWorkflowExecution');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SimpleWorkflow::SignalWorkflowExecution - Arguments for method SignalWorkflowExecution on Paws::SimpleWorkflow

=head1 DESCRIPTION

This class represents the parameters used for calling the method SignalWorkflowExecution on the 
Amazon Simple Workflow Service service. Use the attributes of this class
as arguments to method SignalWorkflowExecution.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to SignalWorkflowExecution.

As an example:

  $service_obj->SignalWorkflowExecution(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> domain => Str

  

The name of the domain containing the workflow execution to signal.










=head2 input => Str

  

Data to attach to the C<WorkflowExecutionSignaled> event in the target
workflow execution's history.










=head2 runId => Str

  

The runId of the workflow execution to signal.










=head2 B<REQUIRED> signalName => Str

  

The name of the signal. This name must be meaningful to the target
workflow.










=head2 B<REQUIRED> workflowId => Str

  

The workflowId of the workflow execution to signal.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SignalWorkflowExecution in L<Paws::SimpleWorkflow>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

