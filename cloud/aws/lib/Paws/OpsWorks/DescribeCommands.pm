
package Paws::OpsWorks::DescribeCommands {
  use Moose;
  has CommandIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has DeploymentId => (is => 'ro', isa => 'Str');
  has InstanceId => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeCommands');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::OpsWorks::DescribeCommandsResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeCommands - Arguments for method DescribeCommands on Paws::OpsWorks

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeCommands on the 
AWS OpsWorks service. Use the attributes of this class
as arguments to method DescribeCommands.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeCommands.

As an example:

  $service_obj->DescribeCommands(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 CommandIds => ArrayRef[Str]

  

An array of command IDs. If you include this parameter,
C<DescribeCommands> returns a description of the specified commands.
Otherwise, it returns a description of every command.










=head2 DeploymentId => Str

  

The deployment ID. If you include this parameter, C<DescribeCommands>
returns a description of the commands associated with the specified
deployment.










=head2 InstanceId => Str

  

The instance ID. If you include this parameter, C<DescribeCommands>
returns a description of the commands associated with the specified
instance.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeCommands in L<Paws::OpsWorks>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

