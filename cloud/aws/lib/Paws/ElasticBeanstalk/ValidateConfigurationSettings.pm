
package Paws::ElasticBeanstalk::ValidateConfigurationSettings {
  use Moose;
  has ApplicationName => (is => 'ro', isa => 'Str', required => 1);
  has EnvironmentName => (is => 'ro', isa => 'Str');
  has OptionSettings => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::ConfigurationOptionSetting]', required => 1);
  has TemplateName => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ValidateConfigurationSettings');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticBeanstalk::ConfigurationSettingsValidationMessages');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ValidateConfigurationSettingsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::ValidateConfigurationSettings - Arguments for method ValidateConfigurationSettings on Paws::ElasticBeanstalk

=head1 DESCRIPTION

This class represents the parameters used for calling the method ValidateConfigurationSettings on the 
AWS Elastic Beanstalk service. Use the attributes of this class
as arguments to method ValidateConfigurationSettings.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ValidateConfigurationSettings.

As an example:

  $service_obj->ValidateConfigurationSettings(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ApplicationName => Str

  

The name of the application that the configuration template or
environment belongs to.










=head2 EnvironmentName => Str

  

The name of the environment to validate the settings against.

Condition: You cannot specify both this and a configuration template
name.










=head2 B<REQUIRED> OptionSettings => ArrayRef[Paws::ElasticBeanstalk::ConfigurationOptionSetting]

  

A list of the options and desired values to evaluate.










=head2 TemplateName => Str

  

The name of the configuration template to validate the settings
against.

Condition: You cannot specify both this and an environment name.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ValidateConfigurationSettings in L<Paws::ElasticBeanstalk>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

