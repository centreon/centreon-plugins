package Paws::EMR::ClusterStatus {
  use Moose;
  has State => (is => 'ro', isa => 'Str');
  has StateChangeReason => (is => 'ro', isa => 'Paws::EMR::ClusterStateChangeReason');
  has Timeline => (is => 'ro', isa => 'Paws::EMR::ClusterTimeline');
}
1;
