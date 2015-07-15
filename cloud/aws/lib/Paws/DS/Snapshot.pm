package Paws::DS::Snapshot {
  use Moose;
  has DirectoryId => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
  has SnapshotId => (is => 'ro', isa => 'Str');
  has StartTime => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Str');
  has Type => (is => 'ro', isa => 'Str');
}
1;
