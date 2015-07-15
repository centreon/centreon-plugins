
package Paws::ElasticBeanstalk::CreateConfigurationTemplate {
  use Moose;
  has ApplicationName => (is => 'ro', isa => 'Str', required => 1);
  has Description => (is => 'ro', isa => 'Str');
  has EnvironmentId => (is => 'ro', isa => 'Str');
  has OptionSettings => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::ConfigurationOptionSetting]');
  has SolutionStackName => (is => 'ro', isa => 'Str');
  has SourceConfiguration => (is => 'ro', isa => 'Paws::ElasticBeanstalk::SourceConfiguration');
  has TemplateName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateConfigurationTemplate');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticBeanstalk::ConfigurationSettingsDescription');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateConfigurationTemplateResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::CreateConfigurationTemplate - Arguments for method CreateConfigurationTemplate on Paws::ElasticBeanstalk

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateConfigurationTemplate on the 
AWS Elastic Beanstalk service. Use the attributes of this class
as arguments to method CreateConfigurationTemplate.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateConfigurationTemplate.

As an example:

  $service_obj->CreateConfigurationTemplate(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ApplicationName => Str

  

The name of the application to associate with this configuration
template. If no application is found with this name, AWS Elastic
Beanstalk returns an C<InvalidParameterValue> error.










=head2 Description => Str

  

Describes this configuration.










=head2 EnvironmentId => Str

  

The ID of the environment used with this configuration template.










=head2 OptionSettings => ArrayRef[Paws::ElasticBeanstalk::ConfigurationOptionSetting]

  

If specified, AWS Elastic Beanstalk sets the specified configuration
option to the requested value. The new value overrides the value
obtained from the solution stack or the source configuration template.










=head2 SolutionStackName => Str

  

The name of the solution stack used by this configuration. The solution
stack specifies the operating system, architecture, and application
server for a configuration template. It determines the set of
configuration options as well as the possible and default values.

Use ListAvailableSolutionStacks to obtain a list of available solution
stacks.

A solution stack name or a source configuration parameter must be
specified, otherwise AWS Elastic Beanstalk returns an
C<InvalidParameterValue> error.

If a solution stack name is not specified and the source configuration
parameter is specified, AWS Elastic Beanstalk uses the same solution
stack as the source configuration template.










=head2 SourceConfiguration => Paws::ElasticBeanstalk::SourceConfiguration

  

If specified, AWS Elastic Beanstalk uses the configuration values from
the specified configuration template to create a new configuration.

Values specified in the C<OptionSettings> parameter of this call
overrides any values obtained from the C<SourceConfiguration>.

If no configuration template is found, returns an
C<InvalidParameterValue> error.

Constraint: If both the solution stack name parameter and the source
configuration parameters are specified, the solution stack of the
source configuration template must match the specified solution stack
name or else AWS Elastic Beanstalk returns an
C<InvalidParameterCombination> error.










=head2 B<REQUIRED> TemplateName => Str

  

The name of the configuration template.

Constraint: This name must be unique per application.

Default: If a configuration template already exists with this name, AWS
Elastic Beanstalk returns an C<InvalidParameterValue> error.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateConfigurationTemplate in L<Paws::ElasticBeanstalk>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

