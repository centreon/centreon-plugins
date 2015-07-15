
package Paws::ElasticBeanstalk::UpdateConfigurationTemplate {
  use Moose;
  has ApplicationName => (is => 'ro', isa => 'Str', required => 1);
  has Description => (is => 'ro', isa => 'Str');
  has OptionSettings => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::ConfigurationOptionSetting]');
  has OptionsToRemove => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::OptionSpecification]');
  has TemplateName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateConfigurationTemplate');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticBeanstalk::ConfigurationSettingsDescription');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'UpdateConfigurationTemplateResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::UpdateConfigurationTemplate - Arguments for method UpdateConfigurationTemplate on Paws::ElasticBeanstalk

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateConfigurationTemplate on the 
AWS Elastic Beanstalk service. Use the attributes of this class
as arguments to method UpdateConfigurationTemplate.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateConfigurationTemplate.

As an example:

  $service_obj->UpdateConfigurationTemplate(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ApplicationName => Str

  

The name of the application associated with the configuration template
to update.

If no application is found with this name,
C<UpdateConfigurationTemplate> returns an C<InvalidParameterValue>
error.










=head2 Description => Str

  

A new description for the configuration.










=head2 OptionSettings => ArrayRef[Paws::ElasticBeanstalk::ConfigurationOptionSetting]

  

A list of configuration option settings to update with the new
specified option value.










=head2 OptionsToRemove => ArrayRef[Paws::ElasticBeanstalk::OptionSpecification]

  

A list of configuration options to remove from the configuration set.

Constraint: You can remove only C<UserDefined> configuration options.










=head2 B<REQUIRED> TemplateName => Str

  

The name of the configuration template to update.

If no configuration template is found with this name,
C<UpdateConfigurationTemplate> returns an C<InvalidParameterValue>
error.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateConfigurationTemplate in L<Paws::ElasticBeanstalk>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

