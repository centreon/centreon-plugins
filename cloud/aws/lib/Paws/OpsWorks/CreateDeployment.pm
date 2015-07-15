
package Paws::OpsWorks::CreateDeployment {
  use Moose;
  has AppId => (is => 'ro', isa => 'Str');
  has Command => (is => 'ro', isa => 'Paws::OpsWorks::DeploymentCommand', required => 1);
  has Comment => (is => 'ro', isa => 'Str');
  has CustomJson => (is => 'ro', isa => 'Str');
  has InstanceIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has StackId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateDeployment');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::OpsWorks::CreateDeploymentResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::CreateDeployment - Arguments for method CreateDeployment on Paws::OpsWorks

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateDeployment on the 
AWS OpsWorks service. Use the attributes of this class
as arguments to method CreateDeployment.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateDeployment.

As an example:

  $service_obj->CreateDeployment(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AppId => Str

  

The app ID. This parameter is required for app deployments, but not for
other deployment commands.










=head2 B<REQUIRED> Command => Paws::OpsWorks::DeploymentCommand

  

A C<DeploymentCommand> object that specifies the deployment command and
any associated arguments.










=head2 Comment => Str

  

A user-defined comment.










=head2 CustomJson => Str

  

A string that contains user-defined, custom JSON. It is used to
override the corresponding default stack configuration JSON values. The
string should be in the following format and must escape characters
such as '"':

C<"{\"key1\": \"value1\", \"key2\": \"value2\",...}">

For more information on custom JSON, see Use Custom JSON to Modify the
Stack Configuration Attributes.










=head2 InstanceIds => ArrayRef[Str]

  

The instance IDs for the deployment targets.










=head2 B<REQUIRED> StackId => Str

  

The stack ID.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateDeployment in L<Paws::OpsWorks>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

