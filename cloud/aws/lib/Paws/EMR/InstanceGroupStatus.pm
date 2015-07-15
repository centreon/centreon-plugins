package Paws::EMR::InstanceGroupStatus {
  use Moose;
  has State => (is => 'ro', isa => 'Str');
  has StateChangeReason => (is => 'ro', isa => 'Paws::EMR::InstanceGroupStateChangeReason');
  has Timeline => (is => 'ro', isa => 'Paws::EMR::InstanceGroupTimeline');
}
1;
