
package Paws::CloudWatchLogs::PutMetricFilter {
  use Moose;
  has filterName => (is => 'ro', isa => 'Str', required => 1);
  has filterPattern => (is => 'ro', isa => 'Str', required => 1);
  has logGroupName => (is => 'ro', isa => 'Str', required => 1);
  has metricTransformations => (is => 'ro', isa => 'ArrayRef[Paws::CloudWatchLogs::MetricTransformation]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PutMetricFilter');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatchLogs::PutMetricFilter - Arguments for method PutMetricFilter on Paws::CloudWatchLogs

=head1 DESCRIPTION

This class represents the parameters used for calling the method PutMetricFilter on the 
Amazon CloudWatch Logs service. Use the attributes of this class
as arguments to method PutMetricFilter.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PutMetricFilter.

As an example:

  $service_obj->PutMetricFilter(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> filterName => Str

  

A name for the metric filter.










=head2 B<REQUIRED> filterPattern => Str

  

A valid CloudWatch Logs filter pattern for extracting metric data out
of ingested log events.










=head2 B<REQUIRED> logGroupName => Str

  

The name of the log group to associate the metric filter with.










=head2 B<REQUIRED> metricTransformations => ArrayRef[Paws::CloudWatchLogs::MetricTransformation]

  

A collection of information needed to define how metric data gets
emitted.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PutMetricFilter in L<Paws::CloudWatchLogs>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

