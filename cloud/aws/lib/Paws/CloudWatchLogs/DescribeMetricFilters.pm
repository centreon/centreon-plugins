
package Paws::CloudWatchLogs::DescribeMetricFilters {
  use Moose;
  has filterNamePrefix => (is => 'ro', isa => 'Str');
  has limit => (is => 'ro', isa => 'Int');
  has logGroupName => (is => 'ro', isa => 'Str', required => 1);
  has nextToken => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeMetricFilters');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudWatchLogs::DescribeMetricFiltersResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatchLogs::DescribeMetricFilters - Arguments for method DescribeMetricFilters on Paws::CloudWatchLogs

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeMetricFilters on the 
Amazon CloudWatch Logs service. Use the attributes of this class
as arguments to method DescribeMetricFilters.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeMetricFilters.

As an example:

  $service_obj->DescribeMetricFilters(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 filterNamePrefix => Str

  

Will only return metric filters that match the provided
filterNamePrefix. If you don't specify a value, no prefix filter is
applied.










=head2 limit => Int

  

The maximum number of items returned in the response. If you don't
specify a value, the request would return up to 50 items.










=head2 B<REQUIRED> logGroupName => Str

  

The log group name for which metric filters are to be listed.










=head2 nextToken => Str

  

A string token used for pagination that points to the next page of
results. It must be a value obtained from the response of the previous
C<DescribeMetricFilters> request.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeMetricFilters in L<Paws::CloudWatchLogs>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

