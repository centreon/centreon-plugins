
package Paws::AutoScaling::ExecutePolicy {
  use Moose;
  has AutoScalingGroupName => (is => 'ro', isa => 'Str');
  has HonorCooldown => (is => 'ro', isa => 'Bool');
  has PolicyName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ExecutePolicy');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::ExecutePolicy - Arguments for method ExecutePolicy on Paws::AutoScaling

=head1 DESCRIPTION

This class represents the parameters used for calling the method ExecutePolicy on the 
Auto Scaling service. Use the attributes of this class
as arguments to method ExecutePolicy.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ExecutePolicy.

As an example:

  $service_obj->ExecutePolicy(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AutoScalingGroupName => Str

  

The name or Amazon Resource Name (ARN) of the Auto Scaling group.










=head2 HonorCooldown => Bool

  

Set to C<True> if you want Auto Scaling to wait for the cooldown period
associated with the Auto Scaling group to complete before executing the
policy.

Set to C<False> if you want Auto Scaling to circumvent the cooldown
period associated with the Auto Scaling group and execute the policy
before the cooldown period ends.

For more information, see Understanding Auto Scaling Cooldowns in the
I<Auto Scaling Developer Guide>.










=head2 B<REQUIRED> PolicyName => Str

  

The name or ARN of the policy.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ExecutePolicy in L<Paws::AutoScaling>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

