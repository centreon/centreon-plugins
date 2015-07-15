
package Paws::CloudWatchLogs::DescribeMetricFiltersResponse {
  use Moose;
  has metricFilters => (is => 'ro', isa => 'ArrayRef[Paws::CloudWatchLogs::MetricFilter]');
  has nextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CloudWatchLogs::DescribeMetricFiltersResponse

=head1 ATTRIBUTES

=head2 metricFilters => ArrayRef[Paws::CloudWatchLogs::MetricFilter]

  
=head2 nextToken => Str

  


=cut

1;