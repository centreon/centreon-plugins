package Paws::OpsWorks::LoadBasedAutoScalingConfiguration {
  use Moose;
  has DownScaling => (is => 'ro', isa => 'Paws::OpsWorks::AutoScalingThresholds');
  has Enable => (is => 'ro', isa => 'Bool');
  has LayerId => (is => 'ro', isa => 'Str');
  has UpScaling => (is => 'ro', isa => 'Paws::OpsWorks::AutoScalingThresholds');
}
1;
