package Paws::EC2::SnapshotDiskContainer {
  use Moose;
  has Description => (is => 'ro', isa => 'Str');
  has Format => (is => 'ro', isa => 'Str');
  has Url => (is => 'ro', isa => 'Str');
  has UserBucket => (is => 'ro', isa => 'Paws::EC2::UserBucket');
}
1;
