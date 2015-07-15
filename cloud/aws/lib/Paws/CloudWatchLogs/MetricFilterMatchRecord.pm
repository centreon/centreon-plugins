package Paws::CloudWatchLogs::MetricFilterMatchRecord {
  use Moose;
  has eventMessage => (is => 'ro', isa => 'Str');
  has eventNumber => (is => 'ro', isa => 'Int');
  has extractedValues => (is => 'ro', isa => 'Paws::CloudWatchLogs::ExtractedValues');
}
1;
