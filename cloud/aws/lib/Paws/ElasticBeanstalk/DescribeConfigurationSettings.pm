
package Paws::ElasticBeanstalk::DescribeConfigurationSettings {
  use Moose;
  has ApplicationName => (is => 'ro', isa => 'Str', required => 1);
  has EnvironmentName => (is => 'ro', isa => 'Str');
  has TemplateName => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeConfigurationSettings');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticBeanstalk::ConfigurationSettingsDescriptions');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeConfigurationSettingsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::DescribeConfigurationSettings - Arguments for method DescribeConfigurationSettings on Paws::ElasticBeanstalk

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeConfigurationSettings on the 
AWS Elastic Beanstalk service. Use the attributes of this class
as arguments to method DescribeConfigurationSettings.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeConfigurationSettings.

As an example:

  $service_obj->DescribeConfigurationSettings(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ApplicationName => Str

  

The application for the environment or configuration template.










=head2 EnvironmentName => Str

  

The name of the environment to describe.

Condition: You must specify either this or a TemplateName, but not
both. If you specify both, AWS Elastic Beanstalk returns an
C<InvalidParameterCombination> error. If you do not specify either, AWS
Elastic Beanstalk returns C<MissingRequiredParameter> error.










=head2 TemplateName => Str

  

The name of the configuration template to describe.

Conditional: You must specify either this parameter or an
EnvironmentName, but not both. If you specify both, AWS Elastic
Beanstalk returns an C<InvalidParameterCombination> error. If you do
not specify either, AWS Elastic Beanstalk returns a
C<MissingRequiredParameter> error.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeConfigurationSettings in L<Paws::ElasticBeanstalk>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

