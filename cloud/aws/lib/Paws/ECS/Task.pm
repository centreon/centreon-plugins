package Paws::ECS::Task {
  use Moose;
  has clusterArn => (is => 'ro', isa => 'Str');
  has containerInstanceArn => (is => 'ro', isa => 'Str');
  has containers => (is => 'ro', isa => 'ArrayRef[Paws::ECS::Container]');
  has desiredStatus => (is => 'ro', isa => 'Str');
  has lastStatus => (is => 'ro', isa => 'Str');
  has overrides => (is => 'ro', isa => 'Paws::ECS::TaskOverride');
  has startedBy => (is => 'ro', isa => 'Str');
  has taskArn => (is => 'ro', isa => 'Str');
  has taskDefinitionArn => (is => 'ro', isa => 'Str');
}
1;
