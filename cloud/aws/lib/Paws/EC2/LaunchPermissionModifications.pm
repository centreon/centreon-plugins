package Paws::EC2::LaunchPermissionModifications {
  use Moose;
  has Add => (is => 'ro', isa => 'ArrayRef[Paws::EC2::LaunchPermission]');
  has Remove => (is => 'ro', isa => 'ArrayRef[Paws::EC2::LaunchPermission]');
}
1;
