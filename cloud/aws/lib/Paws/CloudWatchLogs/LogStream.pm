package Paws::CloudWatchLogs::LogStream {
  use Moose;
  has arn => (is => 'ro', isa => 'Str');
  has creationTime => (is => 'ro', isa => 'Int');
  has firstEventTimestamp => (is => 'ro', isa => 'Int');
  has lastEventTimestamp => (is => 'ro', isa => 'Int');
  has lastIngestionTime => (is => 'ro', isa => 'Int');
  has logStreamName => (is => 'ro', isa => 'Str');
  has storedBytes => (is => 'ro', isa => 'Int');
  has uploadSequenceToken => (is => 'ro', isa => 'Str');
}
1;
