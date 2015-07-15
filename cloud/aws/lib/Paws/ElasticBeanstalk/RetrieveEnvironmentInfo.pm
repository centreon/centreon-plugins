
package Paws::ElasticBeanstalk::RetrieveEnvironmentInfo {
  use Moose;
  has EnvironmentId => (is => 'ro', isa => 'Str');
  has EnvironmentName => (is => 'ro', isa => 'Str');
  has InfoType => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RetrieveEnvironmentInfo');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticBeanstalk::RetrieveEnvironmentInfoResultMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'RetrieveEnvironmentInfoResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::RetrieveEnvironmentInfo - Arguments for method RetrieveEnvironmentInfo on Paws::ElasticBeanstalk

=head1 DESCRIPTION

This class represents the parameters used for calling the method RetrieveEnvironmentInfo on the 
AWS Elastic Beanstalk service. Use the attributes of this class
as arguments to method RetrieveEnvironmentInfo.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RetrieveEnvironmentInfo.

As an example:

  $service_obj->RetrieveEnvironmentInfo(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 EnvironmentId => Str

  

The ID of the data's environment.

If no such environment is found, returns an C<InvalidParameterValue>
error.

Condition: You must specify either this or an EnvironmentName, or both.
If you do not specify either, AWS Elastic Beanstalk returns
C<MissingRequiredParameter> error.










=head2 EnvironmentName => Str

  

The name of the data's environment.

If no such environment is found, returns an C<InvalidParameterValue>
error.

Condition: You must specify either this or an EnvironmentId, or both.
If you do not specify either, AWS Elastic Beanstalk returns
C<MissingRequiredParameter> error.










=head2 B<REQUIRED> InfoType => Str

  

The type of information to retrieve.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RetrieveEnvironmentInfo in L<Paws::ElasticBeanstalk>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

