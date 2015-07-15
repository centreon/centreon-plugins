
package Paws::ElasticBeanstalk::AbortEnvironmentUpdate {
  use Moose;
  has EnvironmentId => (is => 'ro', isa => 'Str');
  has EnvironmentName => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AbortEnvironmentUpdate');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::AbortEnvironmentUpdate - Arguments for method AbortEnvironmentUpdate on Paws::ElasticBeanstalk

=head1 DESCRIPTION

This class represents the parameters used for calling the method AbortEnvironmentUpdate on the 
AWS Elastic Beanstalk service. Use the attributes of this class
as arguments to method AbortEnvironmentUpdate.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to AbortEnvironmentUpdate.

As an example:

  $service_obj->AbortEnvironmentUpdate(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 EnvironmentId => Str

  

This specifies the ID of the environment with the in-progress update
that you want to cancel.










=head2 EnvironmentName => Str

  

This specifies the name of the environment with the in-progress update
that you want to cancel.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method AbortEnvironmentUpdate in L<Paws::ElasticBeanstalk>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

