
package Paws::SimpleWorkflow::PollForActivityTask {
  use Moose;
  has domain => (is => 'ro', isa => 'Str', required => 1);
  has identity => (is => 'ro', isa => 'Str');
  has taskList => (is => 'ro', isa => 'Paws::SimpleWorkflow::TaskList', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PollForActivityTask');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SimpleWorkflow::ActivityTask');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SimpleWorkflow::PollForActivityTask - Arguments for method PollForActivityTask on Paws::SimpleWorkflow

=head1 DESCRIPTION

This class represents the parameters used for calling the method PollForActivityTask on the 
Amazon Simple Workflow Service service. Use the attributes of this class
as arguments to method PollForActivityTask.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PollForActivityTask.

As an example:

  $service_obj->PollForActivityTask(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> domain => Str

  

The name of the domain that contains the task lists being polled.










=head2 identity => Str

  

Identity of the worker making the request, recorded in the
C<ActivityTaskStarted> event in the workflow history. This enables
diagnostic tracing when problems arise. The form of this identity is
user defined.










=head2 B<REQUIRED> taskList => Paws::SimpleWorkflow::TaskList

  

Specifies the task list to poll for activity tasks.

The specified string must not start or end with whitespace. It must not
contain a C<:> (colon), C</> (slash), C<|> (vertical bar), or any
control characters (\u0000-\u001f | \u007f - \u009f). Also, it must not
contain the literal string quotarnquot.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PollForActivityTask in L<Paws::SimpleWorkflow>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

