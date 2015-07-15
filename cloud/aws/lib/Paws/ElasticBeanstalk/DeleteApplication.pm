
package Paws::ElasticBeanstalk::DeleteApplication {
  use Moose;
  has ApplicationName => (is => 'ro', isa => 'Str', required => 1);
  has TerminateEnvByForce => (is => 'ro', isa => 'Bool');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteApplication');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::DeleteApplication - Arguments for method DeleteApplication on Paws::ElasticBeanstalk

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteApplication on the 
AWS Elastic Beanstalk service. Use the attributes of this class
as arguments to method DeleteApplication.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteApplication.

As an example:

  $service_obj->DeleteApplication(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ApplicationName => Str

  

The name of the application to delete.










=head2 TerminateEnvByForce => Bool

  

When set to true, running environments will be terminated before
deleting the application.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteApplication in L<Paws::ElasticBeanstalk>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

