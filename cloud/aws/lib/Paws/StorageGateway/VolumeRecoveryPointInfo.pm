package Paws::StorageGateway::VolumeRecoveryPointInfo {
  use Moose;
  has VolumeARN => (is => 'ro', isa => 'Str');
  has VolumeRecoveryPointTime => (is => 'ro', isa => 'Str');
  has VolumeSizeInBytes => (is => 'ro', isa => 'Int');
  has VolumeUsageInBytes => (is => 'ro', isa => 'Int');
}
1;
