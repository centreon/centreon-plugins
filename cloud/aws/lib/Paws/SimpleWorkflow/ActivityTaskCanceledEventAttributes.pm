package Paws::SimpleWorkflow::ActivityTaskCanceledEventAttributes {
  use Moose;
  has details => (is => 'ro', isa => 'Str');
  has latestCancelRequestedEventId => (is => 'ro', isa => 'Int');
  has scheduledEventId => (is => 'ro', isa => 'Int', required => 1);
  has startedEventId => (is => 'ro', isa => 'Int', required => 1);
}
1;
