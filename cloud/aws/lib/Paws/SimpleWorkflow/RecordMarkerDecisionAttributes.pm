package Paws::SimpleWorkflow::RecordMarkerDecisionAttributes {
  use Moose;
  has details => (is => 'ro', isa => 'Str');
  has markerName => (is => 'ro', isa => 'Str', required => 1);
}
1;
