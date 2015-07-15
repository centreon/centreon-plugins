package Paws::ECS::VolumeFrom {
  use Moose;
  has readOnly => (is => 'ro', isa => 'Bool');
  has sourceContainer => (is => 'ro', isa => 'Str');
}
1;
