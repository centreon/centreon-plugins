package Paws::StorageGateway::VolumeInfo {
  use Moose;
  has VolumeARN => (is => 'ro', isa => 'Str');
  has VolumeType => (is => 'ro', isa => 'Str');
}
1;
