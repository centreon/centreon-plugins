package Paws::ECS::ContainerInstance {
  use Moose;
  has agentConnected => (is => 'ro', isa => 'Bool');
  has agentUpdateStatus => (is => 'ro', isa => 'Str');
  has containerInstanceArn => (is => 'ro', isa => 'Str');
  has ec2InstanceId => (is => 'ro', isa => 'Str');
  has pendingTasksCount => (is => 'ro', isa => 'Int');
  has registeredResources => (is => 'ro', isa => 'ArrayRef[Paws::ECS::Resource]');
  has remainingResources => (is => 'ro', isa => 'ArrayRef[Paws::ECS::Resource]');
  has runningTasksCount => (is => 'ro', isa => 'Int');
  has status => (is => 'ro', isa => 'Str');
  has versionInfo => (is => 'ro', isa => 'Paws::ECS::VersionInfo');
}
1;
