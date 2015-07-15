
package Paws::AutoScaling::RecordLifecycleActionHeartbeat {
  use Moose;
  has AutoScalingGroupName => (is => 'ro', isa => 'Str', required => 1);
  has LifecycleActionToken => (is => 'ro', isa => 'Str', required => 1);
  has LifecycleHookName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RecordLifecycleActionHeartbeat');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::AutoScaling::RecordLifecycleActionHeartbeatAnswer');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'RecordLifecycleActionHeartbeatResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::RecordLifecycleActionHeartbeat - Arguments for method RecordLifecycleActionHeartbeat on Paws::AutoScaling

=head1 DESCRIPTION

This class represents the parameters used for calling the method RecordLifecycleActionHeartbeat on the 
Auto Scaling service. Use the attributes of this class
as arguments to method RecordLifecycleActionHeartbeat.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RecordLifecycleActionHeartbeat.

As an example:

  $service_obj->RecordLifecycleActionHeartbeat(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> AutoScalingGroupName => Str

  

The name of the Auto Scaling group for the hook.










=head2 B<REQUIRED> LifecycleActionToken => Str

  

A token that uniquely identifies a specific lifecycle action associated
with an instance. Auto Scaling sends this token to the notification
target you specified when you created the lifecycle hook.










=head2 B<REQUIRED> LifecycleHookName => Str

  

The name of the lifecycle hook.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RecordLifecycleActionHeartbeat in L<Paws::AutoScaling>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

