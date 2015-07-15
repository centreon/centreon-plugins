
package Paws::OpsWorks::DescribeDeployments {
  use Moose;
  has AppId => (is => 'ro', isa => 'Str');
  has DeploymentIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has StackId => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeDeployments');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::OpsWorks::DescribeDeploymentsResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeDeployments - Arguments for method DescribeDeployments on Paws::OpsWorks

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeDeployments on the 
AWS OpsWorks service. Use the attributes of this class
as arguments to method DescribeDeployments.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeDeployments.

As an example:

  $service_obj->DescribeDeployments(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AppId => Str

  

The app ID. If you include this parameter, C<DescribeDeployments>
returns a description of the commands associated with the specified
app.










=head2 DeploymentIds => ArrayRef[Str]

  

An array of deployment IDs to be described. If you include this
parameter, C<DescribeDeployments> returns a description of the
specified deployments. Otherwise, it returns a description of every
deployment.










=head2 StackId => Str

  

The stack ID. If you include this parameter, C<DescribeDeployments>
returns a description of the commands associated with the specified
stack.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeDeployments in L<Paws::OpsWorks>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

