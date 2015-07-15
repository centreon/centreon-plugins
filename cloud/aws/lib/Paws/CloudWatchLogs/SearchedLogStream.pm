package Paws::CloudWatchLogs::SearchedLogStream {
  use Moose;
  has logStreamName => (is => 'ro', isa => 'Str');
  has searchedCompletely => (is => 'ro', isa => 'Bool');
}
1;
