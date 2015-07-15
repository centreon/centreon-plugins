
package Paws::AutoScaling::PutScalingPolicy {
  use Moose;
  has AdjustmentType => (is => 'ro', isa => 'Str', required => 1);
  has AutoScalingGroupName => (is => 'ro', isa => 'Str', required => 1);
  has Cooldown => (is => 'ro', isa => 'Int');
  has MinAdjustmentStep => (is => 'ro', isa => 'Int');
  has PolicyName => (is => 'ro', isa => 'Str', required => 1);
  has ScalingAdjustment => (is => 'ro', isa => 'Int');

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
before the next scaling activity can start.

For more information, see Understanding Auto Scaling Cooldowns in the
I<Auto Scaling Developer Guide>.










=head2 MinAdjustmentStep => Int

  

Used with C<AdjustmentType> with the value C<PercentChangeInCapacity>,
the scaling policy changes the C<DesiredCapacity> of the Auto Scaling
group by at least the number of instances specified in the value.

You will get a C<ValidationError> if you use C<MinAdjustmentStep> on a
policy with an C<AdjustmentType> other than C<PercentChangeInCapacity>.










=head2 B<REQUIRED> PolicyName => Str

  

The name of the policy.










=head2 ScalingAdjustment => Int

  

The number of instances by which to scale. C<AdjustmentType> determines
the interpretation of this number (for example, as an absolute number
or as a percentage of the existing Auto Scaling group size). A positive
increment adds to the current capacity and a negative value removes
from the current capacity.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PutScalingPolicy in L<Paws::AutoScaling>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

