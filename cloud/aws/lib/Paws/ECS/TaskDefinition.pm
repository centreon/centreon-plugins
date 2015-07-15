package Paws::ECS::TaskDefinition {
  use Moose;
  has containerDefinitions => (is => 'ro', isa => 'ArrayRef[Paws::ECS::ContainerDefinition]');
  has family => (is => 'ro', isa => 'Str');
  has revision => (is => 'ro', isa => 'Int');
  has status => (is => 'ro', isa => 'Str');
  has taskDefinitionArn => (is => 'ro', isa => 'Str');
  has volumes => (is => 'ro', isa => 'ArrayRef[Paws::ECS::Volume]');
}
1;
