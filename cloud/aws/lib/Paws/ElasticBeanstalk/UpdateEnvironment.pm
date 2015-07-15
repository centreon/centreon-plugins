
package Paws::ElasticBeanstalk::UpdateEnvironment {
  use Moose;
  has Description => (is => 'ro', isa => 'Str');
  has EnvironmentId => (is => 'ro', isa => 'Str');
  has EnvironmentName => (is => 'ro', isa => 'Str');
  has OptionSettings => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::ConfigurationOptionSetting]');
  has OptionsToRemove => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::OptionSpecification]');
  has SolutionStackName => (is => 'ro', isa => 'Str');
  has TemplateName => (is => 'ro', isa => 'Str');
  has Tier => (is => 'ro', isa => 'Paws::ElasticBeanstalk::EnvironmentTier');
  has VersionLabel => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateEnvironment');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticBeanstalk::EnvironmentDescription');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'UpdateEnvironmentResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::UpdateEnvironment - Arguments for method UpdateEnvironment on Paws::ElasticBeanstalk

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateEnvironment on the 
AWS Elastic Beanstalk service. Use the attributes of this class
as arguments to method UpdateEnvironment.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateEnvironment.

As an example:

  $service_obj->UpdateEnvironment(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Description => Str

  

If this parameter is specified, AWS Elastic Beanstalk updates the
description of this environment.










=head2 EnvironmentId => Str

  

The ID of the environment to update.

If no environment with this ID exists, AWS Elastic Beanstalk returns an
C<InvalidParameterValue> error.

Condition: You must specify either this or an EnvironmentName, or both.
If you do not specify either, AWS Elastic Beanstalk returns
C<MissingRequiredParameter> error.










=head2 EnvironmentName => Str

  

The name of the environment to update. If no environment with this name
exists, AWS Elastic Beanstalk returns an C<InvalidParameterValue>
error.

Condition: You must specify either this or an EnvironmentId, or both.
If you do not specify either, AWS Elastic Beanstalk returns
C<MissingRequiredParameter> error.










=head2 OptionSettings => ArrayRef[Paws::ElasticBeanstalk::ConfigurationOptionSetting]

  

If specified, AWS Elastic Beanstalk updates the configuration set
associated with the running environment and sets the specified
configuration options to the requested value.










=head2 OptionsToRemove => ArrayRef[Paws::ElasticBeanstalk::OptionSpecification]

  

A list of custom user-defined configuration options to remove from the
configuration set for this environment.










=head2 SolutionStackName => Str

  

This specifies the platform version that the environment will run after
the environment is updated.










=head2 TemplateName => Str

  

If this parameter is specified, AWS Elastic Beanstalk deploys this
configuration template to the environment. If no such configuration
template is found, AWS Elastic Beanstalk returns an
C<InvalidParameterValue> error.










=head2 Tier => Paws::ElasticBeanstalk::EnvironmentTier

  

This specifies the tier to use to update the environment.

Condition: At this time, if you change the tier version, name, or type,
AWS Elastic Beanstalk returns C<InvalidParameterValue> error.










=head2 VersionLabel => Str

  

If this parameter is specified, AWS Elastic Beanstalk deploys the named
application version to the environment. If no such application version
is found, returns an C<InvalidParameterValue> error.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateEnvironment in L<Paws::ElasticBeanstalk>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

