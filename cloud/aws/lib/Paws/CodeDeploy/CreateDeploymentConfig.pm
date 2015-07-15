
package Paws::CodeDeploy::CreateDeploymentConfig {
  use Moose;
  has deploymentConfigName => (is => 'ro', isa => 'Str', required => 1);
  has minimumHealthyHosts => (is => 'ro', isa => 'Paws::CodeDeploy::MinimumHealthyHosts');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateDeploymentConfig');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CodeDeploy::CreateDeploymentConfigOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodeDeploy::CreateDeploymentConfig - Arguments for method CreateDeploymentConfig on Paws::CodeDeploy

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateDeploymentConfig on the 
AWS CodeDeploy service. Use the attributes of this class
as arguments to method CreateDeploymentConfig.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateDeploymentConfig.

As an example:

  $service_obj->CreateDeploymentConfig(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> deploymentConfigName => Str

  

The name of the deployment configuration to create.










=head2 minimumHealthyHosts => Paws::CodeDeploy::MinimumHealthyHosts

  

The minimum number of healthy instances that should be available at any
time during the deployment. There are two parameters expected in the
input: type and value.

The type parameter takes either of the following values:

=over

=item * HOST_COUNT: The value parameter represents the minimum number
of healthy instances, as an absolute value.

=item * FLEET_PERCENT: The value parameter represents the minimum
number of healthy instances, as a percentage of the total number of
instances in the deployment. If you specify FLEET_PERCENT, then at the
start of the deployment AWS CodeDeploy converts the percentage to the
equivalent number of instances and rounds fractional instances up.

=back

The value parameter takes an integer.

For example, to set a minimum of 95% healthy instances, specify a type
of FLEET_PERCENT and a value of 95.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateDeploymentConfig in L<Paws::CodeDeploy>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

