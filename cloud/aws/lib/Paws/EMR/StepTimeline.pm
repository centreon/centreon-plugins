package Paws::EMR::StepTimeline {
  use Moose;
  has CreationDateTime => (is => 'ro', isa => 'Str');
  has EndDateTime => (is => 'ro', isa => 'Str');
  has StartDateTime => (is => 'ro', isa => 'Str');
}
1;
