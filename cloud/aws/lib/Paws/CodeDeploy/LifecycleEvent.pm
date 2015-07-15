package Paws::CodeDeploy::LifecycleEvent {
  use Moose;
  has diagnostics => (is => 'ro', isa => 'Paws::CodeDeploy::Diagnostics');
  has endTime => (is => 'ro', isa => 'Str');
  has lifecycleEventName => (is => 'ro', isa => 'Str');
  has startTime => (is => 'ro', isa => 'Str');
  has status => (is => 'ro', isa => 'Str');
}
1;
