package Paws::CloudWatchLogs::InputLogEvent {
  use Moose;
  has message => (is => 'ro', isa => 'Str', required => 1);
  has timestamp => (is => 'ro', isa => 'Int', required => 1);
}
1;
