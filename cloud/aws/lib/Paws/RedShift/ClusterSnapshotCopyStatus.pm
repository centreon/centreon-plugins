package Paws::RedShift::ClusterSnapshotCopyStatus {
  use Moose;
  has DestinationRegion => (is => 'ro', isa => 'Str');
  has RetentionPeriod => (is => 'ro', isa => 'Int');
  has SnapshotCopyGrantName => (is => 'ro', isa => 'Str');
}
1;
