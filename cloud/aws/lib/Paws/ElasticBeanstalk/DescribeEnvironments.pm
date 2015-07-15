
package Paws::ElasticBeanstalk::DescribeEnvironments {
  use Moose;
  has ApplicationName => (is => 'ro', isa => 'Str');
  has EnvironmentIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has EnvironmentNames => (is => 'ro', isa => 'ArrayRef[Str]');
  has IncludedDeletedBackTo => (is => 'ro', isa => 'Str');
  has IncludeDeleted => (is => 'ro', isa => 'Bool');
  has VersionLabel => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeEnvironments');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticBeanstalk::EnvironmentDescriptionsMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeEnvironmentsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::DescribeEnvironments - Arguments for method DescribeEnvironments on Paws::ElasticBeanstalk

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeEnvironments on the 
AWS Elastic Beanstalk service. Use the attributes of this class
as arguments to method DescribeEnvironments.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeEnvironments.

As an example:

  $service_obj->DescribeEnvironments(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ApplicationName => Str

  

If specified, AWS Elastic Beanstalk restricts the returned descriptions
to include only those that are associated with this application.










=head2 EnvironmentIds => ArrayRef[Str]

  

If specified, AWS Elastic Beanstalk restricts the returned descriptions
to include only those that have the specified IDs.










=head2 EnvironmentNames => ArrayRef[Str]

  

If specified, AWS Elastic Beanstalk restricts the returned descriptions
to include only those that have the specified names.










=head2 IncludedDeletedBackTo => Str

  

If specified when C<IncludeDeleted> is set to C<true>, then
environments deleted after this date are displayed.










=head2 IncludeDeleted => Bool

  

Indicates whether to include deleted environments:

C<true>: Environments that have been deleted after
C<IncludedDeletedBackTo> are displayed.

C<false>: Do not include deleted environments.










=head2 VersionLabel => Str

  

If specified, AWS Elastic Beanstalk restricts the returned descriptions
to include only those that are associated with this application
version.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeEnvironments in L<Paws::ElasticBeanstalk>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

