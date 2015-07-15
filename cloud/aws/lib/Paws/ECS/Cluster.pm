package Paws::ECS::Cluster {
  use Moose;
  has activeServicesCount => (is => 'ro', isa => 'Int');
  has clusterArn => (is => 'ro', isa => 'Str');
  has clusterName => (is => 'ro', isa => 'Str');
  has pendingTasksCount => (is => 'ro', isa => 'Int');
  has registeredContainerInstancesCount => (is => 'ro', isa => 'Int');
  has runningTasksCount => (is => 'ro', isa => 'Int');
  has status => (is => 'ro', isa => 'Str');
}
1;
