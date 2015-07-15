
package Paws::ElasticBeanstalk::UpdateApplication {
  use Moose;
  has ApplicationName => (is => 'ro', isa => 'Str', required => 1);
  has Description => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateApplication');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticBeanstalk::ApplicationDescriptionMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'UpdateApplicationResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::UpdateApplication - Arguments for method UpdateApplication on Paws::ElasticBeanstalk

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateApplication on the 
AWS Elastic Beanstalk service. Use the attributes of this class
as arguments to method UpdateApplication.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateApplication.

As an example:

  $service_obj->UpdateApplication(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ApplicationName => Str

  

The name of the application to update. If no such application is found,
C<UpdateApplication> returns an C<InvalidParameterValue> error.










=head2 Description => Str

  

A new description for the application.

Default: If not specified, AWS Elastic Beanstalk does not update the
description.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateApplication in L<Paws::ElasticBeanstalk>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

