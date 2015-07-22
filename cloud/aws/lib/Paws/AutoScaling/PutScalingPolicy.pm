
package Paws::AutoScaling::PutScalingPolicy {
  use Moose;
  has AdjustmentType => (is => 'ro', isa => 'Str', required => 1);
  has AutoScalingGroupName => (is => 'ro', isa => 'Str', required => 1);
  has Cooldown => (is => 'ro', isa => 'Int');
  has EstimatedInstanceWarmup => (is => 'ro', isa => 'Int');
  has MetricAggregationType => (is => 'ro', isa => 'Str');
  has MinAdjustmentMagnitude => (is => 'ro', isa => 'Int');
  has MinAdjustmentStep => (is => 'ro', isa => 'Int');
  has PolicyName => (is => 'ro', isa => 'Str', required => 1);
  has PolicyType => (is => 'ro', isa => 'Str');
  has ScalingAdjustment => (is => 'ro', isa => 'Int');
  has StepAdjustments => (is => 'ro', isa => 'ArrayRef[Paws::AutoScaling::StepAdjustment]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PutScalingPolicy');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::AutoScaling::PolicyARNType');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'PutScalingPolicyResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::PutScalingPolicy - Arguments for method PutScalingPolicy on Paws::AutoScaling

=head1 DESCRIPTION

This class represents the parameters used for calling the method PutScalingPolicy on the 
Auto Scaling service. Use the attributes of this class
as arguments to method PutScalingPolicy.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PutScalingPolicy.

As an example:

  $service_obj->PutScalingPolicy(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> AdjustmentType => Str

  

The adjustment type. Valid values are C<ChangeInCapacity>,
C<ExactCapacity>, and C<PercentChangeInCapacity>.

For more information, see Dynamic Scaling in the I<Auto Scaling
Developer Guide>.










=head2 B<REQUIRED> AutoScalingGroupName => Str

  

The name or ARN of the group.










=head2 Cooldown => Int

  

The amount of time, in seconds, after a scaling activity completes and
before the next scaling activity can start. If this parameter is not
specified, the default cooldown period for the group applies.

This parameter is not supported unless the policy type is
C<SimpleScaling>.

For more information, see Understanding Auto Scaling Cooldowns in the
I<Auto Scaling Developer Guide>.










=head2 EstimatedInstanceWarmup => Int

  

The estimated time, in seconds, until a newly launched instance can
contribute to the CloudWatch metrics. The default is to use the value
specified for the default cooldown period for the group.

This parameter is not supported if the policy type is C<SimpleScaling>.










=head2 MetricAggregationType => Str

  

The aggregation type for the CloudWatch metrics. Valid values are
C<Minimum>, C<Maximum>, and C<Average>. If the aggregation type is
null, the value is treated as C<Average>.

This parameter is not supported if the policy type is C<SimpleScaling>.










=head2 MinAdjustmentMagnitude => Int

  

The minimum number of instances to scale. If the value of
C<AdjustmentType> is C<PercentChangeInCapacity>, the scaling policy
changes the C<DesiredCapacity> of the Auto Scaling group by at least
this many instances. Otherwise, the error is C<ValidationError>.










=head2 MinAdjustmentStep => Int

  

Available for backward compatibility. Use C<MinAdjustmentMagnitude>
instead.










=head2 B<REQUIRED> PolicyName => Str

  

The name of the policy.










=head2 PolicyType => Str

  

The policy type. Valid values are C<SimpleScaling> and C<StepScaling>.
If the policy type is null, the value is treated as C<SimpleScaling>.










=head2 ScalingAdjustment => Int

  

The amount by which to scale, based on the specified adjustment type. A
positive value adds to the current capacity while a negative number
removes from the current capacity.

This parameter is required if the policy type is C<SimpleScaling> and
not supported otherwise.










=head2 StepAdjustments => ArrayRef[Paws::AutoScaling::StepAdjustment]

  

A set of adjustments that enable you to scale based on the size of the
alarm breach.

This parameter is required if the policy type is C<StepScaling> and not
supported otherwise.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PutScalingPolicy in L<Paws::AutoScaling>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

