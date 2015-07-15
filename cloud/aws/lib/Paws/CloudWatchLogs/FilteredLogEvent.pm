package Paws::CloudWatchLogs::FilteredLogEvent {
  use Moose;
  has eventId => (is => 'ro', isa => 'Str');
  has ingestionTime => (is => 'ro', isa => 'Int');
  has logStreamName => (is => 'ro', isa => 'Str');
  has message => (is => 'ro', isa => 'Str');
  has timestamp => (is => 'ro', isa => 'Int');
}
1;
