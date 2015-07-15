package Paws::EC2::CreateVolumePermissionModifications {
  use Moose;
  has Add => (is => 'ro', isa => 'ArrayRef[Paws::EC2::CreateVolumePermission]');
  has Remove => (is => 'ro', isa => 'ArrayRef[Paws::EC2::CreateVolumePermission]');
}
1;
