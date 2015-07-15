package Paws::OpsWorks::RaidArray {
  use Moose;
  has AvailabilityZone => (is => 'ro', isa => 'Str');
  has CreatedAt => (is => 'ro', isa => 'Str');
  has Device => (is => 'ro', isa => 'Str');
  has InstanceId => (is => 'ro', isa => 'Str');
  has Iops => (is => 'ro', isa => 'Int');
  has MountPoint => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
  has NumberOfDisks => (is => 'ro', isa => 'Int');
  has RaidArrayId => (is => 'ro', isa => 'Str');
  has RaidLevel => (is => 'ro', isa => 'Int');
  has Size => (is => 'ro', isa => 'Int');
  has StackId => (is => 'ro', isa => 'Str');
  has VolumeType => (is => 'ro', isa => 'Str');
}
1;
