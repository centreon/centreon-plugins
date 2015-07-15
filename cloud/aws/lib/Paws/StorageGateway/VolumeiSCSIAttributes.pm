package Paws::StorageGateway::VolumeiSCSIAttributes {
  use Moose;
  has ChapEnabled => (is => 'ro', isa => 'Bool');
  has LunNumber => (is => 'ro', isa => 'Int');
  has NetworkInterfaceId => (is => 'ro', isa => 'Str');
  has NetworkInterfacePort => (is => 'ro', isa => 'Int');
  has TargetARN => (is => 'ro', isa => 'Str');
}
1;
