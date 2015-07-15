
package Paws::ElasticBeanstalk::CreateApplication {
  use Moose;
  has ApplicationName => (is => 'ro', isa => 'Str', required => 1);
  has Description => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateApplication');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticBeanstalk::ApplicationDescriptionMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateApplicationResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::CreateApplication - Arguments for method CreateApplication on Paws::ElasticBeanstalk

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateApplication on the 
AWS Elastic Beanstalk service. Use the attributes of this class
as arguments to method CreateApplication.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateApplication.

As an example:

  $service_obj->CreateApplication(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ApplicationName => Str

  

The name of the application.

Constraint: This name must be unique within your account. If the
specified name already exists, the action returns an
C<InvalidParameterValue> error.










=head2 Description => Str

  

Describes the application.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateApplication in L<Paws::ElasticBeanstalk>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

