package Paws::CloudWatchLogs::MetricTransformation {
  use Moose;
  has metricName => (is => 'ro', isa => 'Str', required => 1);
  has metricNamespace => (is => 'ro', isa => 'Str', required => 1);
  has metricValue => (is => 'ro', isa => 'Str', required => 1);
}
1;
