package Paws::CloudSearch::ScalingParameters {
  use Moose;
  has DesiredInstanceType => (is => 'ro', isa => 'Str');
  has DesiredPartitionCount => (is => 'ro', isa => 'Int');
  has DesiredReplicationCount => (is => 'ro', isa => 'Int');
}
1;
