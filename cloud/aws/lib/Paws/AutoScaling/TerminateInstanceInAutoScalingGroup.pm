
package Paws::AutoScaling::TerminateInstanceInAutoScalingGroup {
  use Moose;
  has InstanceId => (is => 'ro', isa => 'Str', required => 1);
  has ShouldDecrementDesiredCapacity => (is => 'ro', isa => 'Bool', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'TerminateInstanceInAutoScalingGroup');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::AutoScaling::ActivityType');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'TerminateInstanceInAutoScalingGroupResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::TerminateInstanceInAutoScalingGroup - Arguments for method TerminateInstanceInAutoScalingGroup on Paws::AutoScaling

=head1 DESCRIPTION

This class represents the parameters used for calling the method TerminateInstanceInAutoScalingGroup on the 
Auto Scaling service. Use the attributes of this class
as arguments to method TerminateInstanceInAutoScalingGroup.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to TerminateInstanceInAutoScalingGroup.

As an example:

  $service_obj->TerminateInstanceInAutoScalingGroup(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> InstanceId => Str

  

The ID of the EC2 instance.










=head2 B<REQUIRED> ShouldDecrementDesiredCapacity => Bool

  

If C<true>, terminating this instance also decrements the size of the
Auto Scaling group.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method TerminateInstanceInAutoScalingGroup in L<Paws::AutoScaling>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

