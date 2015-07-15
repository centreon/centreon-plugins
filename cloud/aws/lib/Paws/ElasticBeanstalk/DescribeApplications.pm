
package Paws::ElasticBeanstalk::DescribeApplications {
  use Moose;
  has ApplicationNames => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeApplications');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticBeanstalk::ApplicationDescriptionsMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeApplicationsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::DescribeApplications - Arguments for method DescribeApplications on Paws::ElasticBeanstalk

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeApplications on the 
AWS Elastic Beanstalk service. Use the attributes of this class
as arguments to method DescribeApplications.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeApplications.

As an example:

  $service_obj->DescribeApplications(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ApplicationNames => ArrayRef[Str]

  

If specified, AWS Elastic Beanstalk restricts the returned descriptions
to only include those with the specified names.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeApplications in L<Paws::ElasticBeanstalk>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

