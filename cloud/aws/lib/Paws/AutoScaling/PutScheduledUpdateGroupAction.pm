
package Paws::AutoScaling::PutScheduledUpdateGroupAction {
  use Moose;
  has AutoScalingGroupName => (is => 'ro', isa => 'Str', required => 1);
  has DesiredCapacity => (is => 'ro', isa => 'Int');
  has EndTime => (is => 'ro', isa => 'Str');
  has MaxSize => (is => 'ro', isa => 'Int');
  has MinSize => (is => 'ro', isa => 'Int');
  has Recurrence => (is => 'ro', isa => 'Str');
  has ScheduledActionName => (is => 'ro', isa => 'Str', required => 1);
  has StartTime => (is => 'ro', isa => 'Str');
  has Time => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PutScheduledUpdateGroupAction');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::PutScheduledUpdateGroupAction - Arguments for method PutScheduledUpdateGroupAction on Paws::AutoScaling

=head1 DESCRIPTION

This class represents the parameters used for calling the method PutScheduledUpdateGroupAction on the 
Auto Scaling service. Use the attributes of this class
as arguments to method PutScheduledUpdateGroupAction.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PutScheduledUpdateGroupAction.

As an example:

  $service_obj->PutScheduledUpdateGroupAction(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> AutoScalingGroupName => Str

  

The name or Amazon Resource Name (ARN) of the Auto Scaling group.










=head2 DesiredCapacity => Int

  

The number of EC2 instances that should be running in the group.










=head2 EndTime => Str

  

The time for this action to end.










=head2 MaxSize => Int

  

The maximum size for the Auto Scaling group.










=head2 MinSize => Int

  

The minimum size for the Auto Scaling group.










=head2 Recurrence => Str

  

The time when recurring future actions will start. Start time is
specified by the user following the Unix cron syntax format. For more
information, see Cron in Wikipedia.

When C<StartTime> and C<EndTime> are specified with C<Recurrence>, they
form the boundaries of when the recurring action will start and stop.










=head2 B<REQUIRED> ScheduledActionName => Str

  

The name of this scaling action.










=head2 StartTime => Str

  

The time for this action to start, in "YYYY-MM-DDThh:mm:ssZ" format in
UTC/GMT only (for example, C<2014-06-01T00:00:00Z>).

If you try to schedule your action in the past, Auto Scaling returns an
error message.

When C<StartTime> and C<EndTime> are specified with C<Recurrence>, they
form the boundaries of when the recurring action starts and stops.










=head2 Time => Str

  

C<Time> is deprecated; use C<StartTime> instead.

The time for this action to start. If both C<Time> and C<StartTime> are
specified, their values must be identical.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PutScheduledUpdateGroupAction in L<Paws::AutoScaling>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

