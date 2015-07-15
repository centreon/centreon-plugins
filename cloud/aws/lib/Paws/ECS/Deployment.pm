package Paws::ECS::Deployment {
  use Moose;
  has createdAt => (is => 'ro', isa => 'Str');
  has desiredCount => (is => 'ro', isa => 'Int');
  has id => (is => 'ro', isa => 'Str');
  has pendingCount => (is => 'ro', isa => 'Int');
  has runningCount => (is => 'ro', isa => 'Int');
  has status => (is => 'ro', isa => 'Str');
  has taskDefinition => (is => 'ro', isa => 'Str');
  has updatedAt => (is => 'ro', isa => 'Str');
}
1;
