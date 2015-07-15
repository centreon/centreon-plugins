package Paws::EC2::ImageDiskContainer {
  use Moose;
  has Description => (is => 'ro', isa => 'Str');
  has DeviceName => (is => 'ro', isa => 'Str');
  has Format => (is => 'ro', isa => 'Str');
  has SnapshotId => (is => 'ro', isa => 'Str');
  has Url => (is => 'ro', isa => 'Str');
  has UserBucket => (is => 'ro', isa => 'Paws::EC2::UserBucket');
}
1;
