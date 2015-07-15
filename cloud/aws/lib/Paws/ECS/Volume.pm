package Paws::ECS::Volume {
  use Moose;
  has host => (is => 'ro', isa => 'Paws::ECS::HostVolumeProperties');
  has name => (is => 'ro', isa => 'Str');
}
1;
