package Paws::SimpleWorkflow::RecordMarkerFailedEventAttributes {
  use Moose;
  has cause => (is => 'ro', isa => 'Str', required => 1);
  has decisionTaskCompletedEventId => (is => 'ro', isa => 'Int', required => 1);
  has markerName => (is => 'ro', isa => 'Str', required => 1);
}
1;
