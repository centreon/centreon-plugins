package Paws::AutoScaling::ScalingPolicy {
  use Moose;
  has AdjustmentType => (is => 'ro', isa => 'Str');
  has Alarms => (is => 'ro', isa => 'ArrayRef[Paws::AutoScaling::Alarm]');
  has AutoScalingGroupName => (is => 'ro', isa => 'Str');
  has Cooldown => (is => 'ro', isa => 'Int');
  has EstimatedInstanceWarmup => (is => 'ro', isa => 'Int');
  has MetricAggregationType => (is => 'ro', isa => 'Str');
  has MinAdjustmentMagnitude => (is => 'ro', isa => 'Int');
  has MinAdjustmentStep => (is => 'ro', isa => 'Int');
  has PolicyARN => (is => 'ro', isa => 'Str');
  has PolicyName => (is => 'ro', isa => 'Str');
  has PolicyType => (is => 'ro', isa => 'Str');
  has ScalingAdjustment => (is => 'ro', isa => 'Int');
  has StepAdjustments => (is => 'ro', isa => 'ArrayRef[Paws::AutoScaling::StepAdjustment]');
}
1;
