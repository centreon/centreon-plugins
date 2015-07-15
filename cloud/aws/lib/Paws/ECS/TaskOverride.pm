package Paws::ECS::TaskOverride {
  use Moose;
  has containerOverrides => (is => 'ro', isa => 'ArrayRef[Paws::ECS::ContainerOverride]');
}
1;
