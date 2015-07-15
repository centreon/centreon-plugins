package Paws::OpsWorks::VolumeConfiguration {
  use Moose;
  has Iops => (is => 'ro', isa => 'Int');
  has MountPoint => (is => 'ro', isa => 'Str', required => 1);
  has NumberOfDisks => (is => 'ro', isa => 'Int', required => 1);
  has RaidLevel => (is => 'ro', isa => 'Int');
  has Size => (is => 'ro', isa => 'Int', required => 1);
  has VolumeType => (is => 'ro', isa => 'Str');
}
1;
