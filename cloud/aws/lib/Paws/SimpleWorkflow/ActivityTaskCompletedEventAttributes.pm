package Paws::SimpleWorkflow::ActivityTaskCompletedEventAttributes {
  use Moose;
  has result => (is => 'ro', isa => 'Str');
  has scheduledEventId => (is => 'ro', isa => 'Int', required => 1);
  has startedEventId => (is => 'ro', isa => 'Int', required => 1);
}
1;
