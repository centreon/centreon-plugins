
package Paws::ElasticBeanstalk::DescribeEvents {
  use Moose;
  has ApplicationName => (is => 'ro', isa => 'Str');
  has EndTime => (is => 'ro', isa => 'Str');
  has EnvironmentId => (is => 'ro', isa => 'Str');
  has EnvironmentName => (is => 'ro', isa => 'Str');
  has MaxRecords => (is => 'ro', isa => 'Int');
  has NextToken => (is => 'ro', isa => 'Str');
  has RequestId => (is => 'ro', isa => 'Str');
  has Severity => (is => 'ro', isa => 'Str');
  has StartTime => (is => 'ro', isa => 'Str');
  has TemplateName => (is => 'ro', isa => 'Str');
  has VersionLabel => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeEvents');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticBeanstalk::EventDescriptionsMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeEventsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::DescribeEvents - Arguments for method DescribeEvents on Paws::ElasticBeanstalk

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeEvents on the 
AWS Elastic Beanstalk service. Use the attributes of this class
as arguments to method DescribeEvents.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeEvents.

As an example:

  $service_obj->DescribeEvents(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ApplicationName => Str

  

If specified, AWS Elastic Beanstalk restricts the returned descriptions
to include only those associated with this application.










=head2 EndTime => Str

  

If specified, AWS Elastic Beanstalk restricts the returned descriptions
to those that occur up to, but not including, the C<EndTime>.










=head2 EnvironmentId => Str

  

If specified, AWS Elastic Beanstalk restricts the returned descriptions
to those associated with this environment.










=head2 EnvironmentName => Str

  

If specified, AWS Elastic Beanstalk restricts the returned descriptions
to those associated with this environment.










=head2 MaxRecords => Int

  

Specifies the maximum number of events that can be returned, beginning
with the most recent event.










=head2 NextToken => Str

  

Pagination token. If specified, the events return the next batch of
results.










=head2 RequestId => Str

  

If specified, AWS Elastic Beanstalk restricts the described events to
include only those associated with this request ID.










=head2 Severity => Str

  

If specified, limits the events returned from this call to include only
those with the specified severity or higher.










=head2 StartTime => Str

  

If specified, AWS Elastic Beanstalk restricts the returned descriptions
to those that occur on or after this time.










=head2 TemplateName => Str

  

If specified, AWS Elastic Beanstalk restricts the returned descriptions
to those that are associated with this environment configuration.










=head2 VersionLabel => Str

  

If specified, AWS Elastic Beanstalk restricts the returned descriptions
to those associated with this application version.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeEvents in L<Paws::ElasticBeanstalk>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

