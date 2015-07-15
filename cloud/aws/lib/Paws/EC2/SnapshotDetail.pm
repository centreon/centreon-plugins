package Paws::EC2::SnapshotDetail {
  use Moose;
  has Description => (is => 'ro', isa => 'Str', xmlname => 'description', traits => ['Unwrapped']);
  has DeviceName => (is => 'ro', isa => 'Str', xmlname => 'deviceName', traits => ['Unwrapped']);
  has DiskImageSize => (is => 'ro', isa => 'Num', xmlname => 'diskImageSize', traits => ['Unwrapped']);
  has Format => (is => 'ro', isa => 'Str', xmlname => 'format', traits => ['Unwrapped']);
  has Progress => (is => 'ro', isa => 'Str', xmlname => 'progress', traits => ['Unwrapped']);
  has SnapshotId => (is => 'ro', isa => 'Str', xmlname => 'snapshotId', traits => ['Unwrapped']);
  has Status => (is => 'ro', isa => 'Str', xmlname => 'status', traits => ['Unwrapped']);
  has StatusMessage => (is => 'ro', isa => 'Str', xmlname => 'statusMessage', traits => ['Unwrapped']);
  has Url => (is => 'ro', isa => 'Str', xmlname => 'url', traits => ['Unwrapped']);
  has UserBucket => (is => 'ro', isa => 'Paws::EC2::UserBucketDetails', xmlname => 'userBucket', traits => ['Unwrapped']);
}
1;
