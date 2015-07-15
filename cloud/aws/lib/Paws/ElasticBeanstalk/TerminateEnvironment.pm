
package Paws::ElasticBeanstalk::TerminateEnvironment {
  use Moose;
  has EnvironmentId => (is => 'ro', isa => 'Str');
  has EnvironmentName => (is => 'ro', isa => 'Str');
  has TerminateResources => (is => 'ro', isa => 'Bool');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'TerminateEnvironment');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticBeanstalk::EnvironmentDescription');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'TerminateEnvironmentResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::TerminateEnvironment - Arguments for method TerminateEnvironment on Paws::ElasticBeanstalk

=head1 DESCRIPTION

This class represents the parameters used for calling the method TerminateEnvironment on the 
AWS Elastic Beanstalk service. Use the attributes of this class
as arguments to method TerminateEnvironment.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to TerminateEnvironment.

As an example:

  $service_obj->TerminateEnvironment(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 EnvironmentId => Str

  

The ID of the environment to terminate.

Condition: You must specify either this or an EnvironmentName, or both.
If you do not specify either, AWS Elastic Beanstalk returns
C<MissingRequiredParameter> error.










=head2 EnvironmentName => Str

  

The name of the environment to terminate.

Condition: You must specify either this or an EnvironmentId, or both.
If you do not specify either, AWS Elastic Beanstalk returns
C<MissingRequiredParameter> error.










=head2 TerminateResources => Bool

  

Indicates whether the associated AWS resources should shut down when
the environment is terminated:

C<true>: (default) The user AWS resources (for example, the Auto
Scaling group, LoadBalancer, etc.) are terminated along with the
environment.

C<false>: The environment is removed from the AWS Elastic Beanstalk but
the AWS resources continue to operate.

=over

=item * C<true>: The specified environment as well as the associated
AWS resources, such as Auto Scaling group and LoadBalancer, are
terminated.

=item * C<false>: AWS Elastic Beanstalk resource management is removed
from the environment, but the AWS resources continue to operate.

=back

For more information, see the AWS Elastic Beanstalk User Guide.

Default: C<true>

Valid Values: C<true> | C<false>












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method TerminateEnvironment in L<Paws::ElasticBeanstalk>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

