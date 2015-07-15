package Paws::ECS::Service {
  use Moose;
  has clusterArn => (is => 'ro', isa => 'Str');
  has deployments => (is => 'ro', isa => 'ArrayRef[Paws::ECS::Deployment]');
  has desiredCount => (is => 'ro', isa => 'Int');
  has events => (is => 'ro', isa => 'ArrayRef[Paws::ECS::ServiceEvent]');
  has loadBalancers => (is => 'ro', isa => 'ArrayRef[Paws::ECS::LoadBalancer]');
  has pendingCount => (is => 'ro', isa => 'Int');
  has roleArn => (is => 'ro', isa => 'Str');
  has runningCount => (is => 'ro', isa => 'Int');
  has serviceArn => (is => 'ro', isa => 'Str');
  has serviceName => (is => 'ro', isa => 'Str');
  has status => (is => 'ro', isa => 'Str');
  has taskDefinition => (is => 'ro', isa => 'Str');
}
1;
