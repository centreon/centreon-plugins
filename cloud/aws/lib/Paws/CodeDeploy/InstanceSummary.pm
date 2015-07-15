package Paws::CodeDeploy::InstanceSummary {
  use Moose;
  has deploymentId => (is => 'ro', isa => 'Str');
  has instanceId => (is => 'ro', isa => 'Str');
  has lastUpdatedAt => (is => 'ro', isa => 'Str');
  has lifecycleEvents => (is => 'ro', isa => 'ArrayRef[Paws::CodeDeploy::LifecycleEvent]');
  has status => (is => 'ro', isa => 'Str');
}
1;
