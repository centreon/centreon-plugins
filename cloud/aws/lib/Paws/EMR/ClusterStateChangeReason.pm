package Paws::EMR::ClusterStateChangeReason {
  use Moose;
  has Code => (is => 'ro', isa => 'Str');
  has Message => (is => 'ro', isa => 'Str');
}
1;
