package Paws::CloudWatchLogs::MetricFilter {
  use Moose;
  has creationTime => (is => 'ro', isa => 'Int');
  has filterName => (is => 'ro', isa => 'Str');
  has filterPattern => (is => 'ro', isa => 'Str');
  has metricTransformations => (is => 'ro', isa => 'ArrayRef[Paws::CloudWatchLogs::MetricTransformation]');
}
1;
