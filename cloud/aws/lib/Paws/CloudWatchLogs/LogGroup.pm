package Paws::CloudWatchLogs::LogGroup {
  use Moose;
  has arn => (is => 'ro', isa => 'Str');
  has creationTime => (is => 'ro', isa => 'Int');
  has logGroupName => (is => 'ro', isa => 'Str');
  has metricFilterCount => (is => 'ro', isa => 'Int');
  has retentionInDays => (is => 'ro', isa => 'Int');
  has storedBytes => (is => 'ro', isa => 'Int');
}
1;
