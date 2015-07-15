package Paws::EMR::InstanceGroupTimeline {
  use Moose;
  has CreationDateTime => (is => 'ro', isa => 'Str');
  has EndDateTime => (is => 'ro', isa => 'Str');
  has ReadyDateTime => (is => 'ro', isa => 'Str');
}
1;
