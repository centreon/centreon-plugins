package Paws::EMR::StepStatus {
  use Moose;
  has State => (is => 'ro', isa => 'Str');
  has StateChangeReason => (is => 'ro', isa => 'Paws::EMR::StepStateChangeReason');
  has Timeline => (is => 'ro', isa => 'Paws::EMR::StepTimeline');
}
1;
