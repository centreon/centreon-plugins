package Paws::DS::SnapshotLimits {
  use Moose;
  has ManualSnapshotsCurrentCount => (is => 'ro', isa => 'Int');
  has ManualSnapshotsLimit => (is => 'ro', isa => 'Int');
  has ManualSnapshotsLimitReached => (is => 'ro', isa => 'Bool');
}
1;
