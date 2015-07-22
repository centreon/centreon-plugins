package Paws::AutoScaling::StepAdjustment {
  use Moose;
  has MetricIntervalLowerBound => (is => 'ro', isa => 'Num');
  has MetricIntervalUpperBound => (is => 'ro', isa => 'Num');
  has ScalingAdjustment => (is => 'ro', isa => 'Int', required => 1);
}
1;
