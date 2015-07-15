package Paws::SimpleWorkflow::DecisionTaskStartedEventAttributes {
  use Moose;
  has identity => (is => 'ro', isa => 'Str');
  has scheduledEventId => (is => 'ro', isa => 'Int', required => 1);
}
1;
