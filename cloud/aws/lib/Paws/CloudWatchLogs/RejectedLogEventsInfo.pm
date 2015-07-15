package Paws::CloudWatchLogs::RejectedLogEventsInfo {
  use Moose;
  has expiredLogEventEndIndex => (is => 'ro', isa => 'Int');
  has tooNewLogEventStartIndex => (is => 'ro', isa => 'Int');
  has tooOldLogEventEndIndex => (is => 'ro', isa => 'Int');
}
1;
