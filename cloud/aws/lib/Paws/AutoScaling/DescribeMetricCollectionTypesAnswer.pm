
package Paws::AutoScaling::DescribeMetricCollectionTypesAnswer {
  use Moose;
  has Granularities => (is => 'ro', isa => 'ArrayRef[Paws::AutoScaling::MetricGranularityType]');
  has Metrics => (is => 'ro', isa => 'ArrayRef[Paws::AutoScaling::MetricCollectionType]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::DescribeMetricCollectionTypesAnswer

=head1 ATTRIBUTES

=head2 Granularities => ArrayRef[Paws::AutoScaling::MetricGranularityType]

  

The granularities for the metrics.









=head2 Metrics => ArrayRef[Paws::AutoScaling::MetricCollectionType]

  

One or more metrics.











=cut

