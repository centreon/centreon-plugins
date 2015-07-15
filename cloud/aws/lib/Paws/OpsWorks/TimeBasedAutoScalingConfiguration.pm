package Paws::OpsWorks::TimeBasedAutoScalingConfiguration {
  use Moose;
  has AutoScalingSchedule => (is => 'ro', isa => 'Paws::OpsWorks::WeeklyAutoScalingSchedule');
  has InstanceId => (is => 'ro', isa => 'Str');
}
1;
