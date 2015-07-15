
package Paws::ElasticBeanstalk::CreateEnvironment {
  use Moose;
  has ApplicationName => (is => 'ro', isa => 'Str', required => 1);
  has CNAMEPrefix => (is => 'ro', isa => 'Str');
  has Description => (is => 'ro', isa => 'Str');
  has EnvironmentName => (is => 'ro', isa => 'Str', required => 1);
  has OptionSettings => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::ConfigurationOptionSetting]');
  has OptionsToRemove => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::OptionSpecification]');
  has SolutionStackName => (is => 'ro', isa => 'Str');
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::Tag]');
  has TemplateName => (is => 'ro', isa => 'Str');
  has Tier => (is => 'ro', isa => 'Paws::ElasticBeanstalk::EnvironmentTier');
  has VersionLabel => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateEnvironment');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticBeanstalk::EnvironmentDescription');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateEnvironmentResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::CreateEnvironment - Arguments for method CreateEnvironment on Paws::ElasticBeanstalk

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateEnvironment on the 
AWS Elastic Beanstalk service. Use the attributes of this class
as arguments to method CreateEnvironment.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateEnvironment.

As an example:

  $service_obj->CreateEnvironment(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ApplicationName => Str

  

The name of the application that contains the version to be deployed.

If no application is found with this name, C<CreateEnvironment> returns
an C<InvalidParameterValue> error.










=head2 CNAMEPrefix => Str

  

If specified, the environment attempts to use this value as the prefix
for the CNAME. If not specified, the CNAME is generated automatically
by appending a random alphanumeric string to the environment name.










=head2 Description => Str

  

Describes this environment.










=head2 B<REQUIRED> EnvironmentName => Str

  

A unique name for the deployment environment. Used in the application
URL.

Constraint: Must be from 4 to 23 characters in length. The name can
contain only letters, numbers, and hyphens. It cannot start or end with
a hyphen. This name must be unique in your account. If the specified
name already exists, AWS Elastic Beanstalk returns an
C<InvalidParameterValue> error.

Default: If the CNAME parameter is not specified, the environment name
becomes part of the CNAME, and therefore part of the visible URL for
your application.










=head2 OptionSettings => ArrayRef[Paws::ElasticBeanstalk::ConfigurationOptionSetting]

  

If specified, AWS Elastic Beanstalk sets the specified configuration
options to the requested value in the configuration set for the new
environment. These override the values obtained from the solution stack
or the configuration template.










=head2 OptionsToRemove => ArrayRef[Paws::ElasticBeanstalk::OptionSpecification]

  

A list of custom user-defined configuration options to remove from the
configuration set for this new environment.










=head2 SolutionStackName => Str

  

This is an alternative to specifying a configuration name. If
specified, AWS Elastic Beanstalk sets the configuration values to the
default values associated with the specified solution stack.

Condition: You must specify either this or a C<TemplateName>, but not
both. If you specify both, AWS Elastic Beanstalk returns an
C<InvalidParameterCombination> error. If you do not specify either, AWS
Elastic Beanstalk returns a C<MissingRequiredParameter> error.










=head2 Tags => ArrayRef[Paws::ElasticBeanstalk::Tag]

  

This specifies the tags applied to resources in the environment.










=head2 TemplateName => Str

  

The name of the configuration template to use in deployment. If no
configuration template is found with this name, AWS Elastic Beanstalk
returns an C<InvalidParameterValue> error.

Condition: You must specify either this parameter or a
C<SolutionStackName>, but not both. If you specify both, AWS Elastic
Beanstalk returns an C<InvalidParameterCombination> error. If you do
not specify either, AWS Elastic Beanstalk returns a
C<MissingRequiredParameter> error.










=head2 Tier => Paws::ElasticBeanstalk::EnvironmentTier

  

This specifies the tier to use for creating this environment.










=head2 VersionLabel => Str

  

The name of the application version to deploy.

If the specified application has no associated application versions,
AWS Elastic Beanstalk C<UpdateEnvironment> returns an
C<InvalidParameterValue> error.

Default: If not specified, AWS Elastic Beanstalk attempts to launch the
sample application in the container.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateEnvironment in L<Paws::ElasticBeanstalk>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

