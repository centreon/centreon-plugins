package Paws::AutoScaling::Instance {
  use Moose;
  has AvailabilityZone => (is => 'ro', isa => 'Str', required => 1);
  has HealthStatus => (is => 'ro', isa => 'Str', required => 1);
  has InstanceId => (is => 'ro', isa => 'Str', required => 1);
  has LaunchConfigurationName => (is => 'ro', isa => 'Str');
  has LifecycleState => (is => 'ro', isa => 'Str', required => 1);
}
1;
