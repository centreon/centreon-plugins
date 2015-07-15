package Paws::EC2::EbsBlockDevice {
  use Moose;
  has DeleteOnTermination => (is => 'ro', isa => 'Bool', xmlname => 'deleteOnTermination', traits => ['Unwrapped']);
  has Encrypted => (is => 'ro', isa => 'Bool', xmlname => 'encrypted', traits => ['Unwrapped']);
  has Iops => (is => 'ro', isa => 'Int', xmlname => 'iops', traits => ['Unwrapped']);
  has SnapshotId => (is => 'ro', isa => 'Str', xmlname => 'snapshotId', traits => ['Unwrapped']);
  has VolumeSize => (is => 'ro', isa => 'Int', xmlname => 'volumeSize', traits => ['Unwrapped']);
  has VolumeType => (is => 'ro', isa => 'Str', xmlname => 'volumeType', traits => ['Unwrapped']);
}
1;
