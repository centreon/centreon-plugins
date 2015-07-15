package Paws::OpsWorks::Volume {
  use Moose;
  has AvailabilityZone => (is => 'ro', isa => 'Str');
  has Device => (is => 'ro', isa => 'Str');
  has Ec2VolumeId => (is => 'ro', isa => 'Str');
  has InstanceId => (is => 'ro', isa => 'Str');
  has Iops => (is => 'ro', isa => 'Int');
  has MountPoint => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
  has RaidArrayId => (is => 'ro', isa => 'Str');
  has Region => (is => 'ro', isa => 'Str');
  has Size => (is => 'ro', isa => 'Int');
  has Status => (is => 'ro', isa => 'Str');
  has VolumeId => (is => 'ro', isa => 'Str');
  has VolumeType => (is => 'ro', isa => 'Str');
}
1;
