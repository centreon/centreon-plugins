package Paws::CloudWatchLogs::OutputLogEvent {
  use Moose;
  has ingestionTime => (is => 'ro', isa => 'Int');
  has message => (is => 'ro', isa => 'Str');
  has timestamp => (is => 'ro', isa => 'Int');
}
1;
