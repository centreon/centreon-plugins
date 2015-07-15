package Paws::ECS::ContainerOverride {
  use Moose;
  has command => (is => 'ro', isa => 'ArrayRef[Str]');
  has environment => (is => 'ro', isa => 'ArrayRef[Paws::ECS::KeyValuePair]');
  has name => (is => 'ro', isa => 'Str');
}
1;
