package Paws::ECS::MountPoint {
  use Moose;
  has containerPath => (is => 'ro', isa => 'Str');
  has readOnly => (is => 'ro', isa => 'Bool');
  has sourceVolume => (is => 'ro', isa => 'Str');
}
1;
