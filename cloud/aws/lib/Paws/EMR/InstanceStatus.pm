package Paws::EMR::InstanceStatus {
  use Moose;
  has State => (is => 'ro', isa => 'Str');
  has StateChangeReason => (is => 'ro', isa => 'Paws::EMR::InstanceStateChangeReason');
  has Timeline => (is => 'ro', isa => 'Paws::EMR::InstanceTimeline');
}
1;
