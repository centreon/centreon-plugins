package Paws::AutoScaling::LifecycleHook {
  use Moose;
  has AutoScalingGroupName => (is => 'ro', isa => 'Str');
  has DefaultResult => (is => 'ro', isa => 'Str');
  has GlobalTimeout => (is => 'ro', isa => 'Int');
  has HeartbeatTimeout => (is => 'ro', isa => 'Int');
  has LifecycleHookName => (is => 'ro', isa => 'Str');
  has LifecycleTransition => (is => 'ro', isa => 'Str');
  has NotificationMetadata => (is => 'ro', isa => 'Str');
  has NotificationTargetARN => (is => 'ro', isa => 'Str');
  has RoleARN => (is => 'ro', isa => 'Str');
}
1;
