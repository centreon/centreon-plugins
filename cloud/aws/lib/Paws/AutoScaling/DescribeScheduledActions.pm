
package Paws::AutoScaling::DescribeScheduledActions {
  use Moose;
  has AutoScalingGroupName => (is => 'ro', isa => 'Str');
  has EndTime => (is => 'ro', isa => 'Str');
  has MaxRecords => (is => 'ro', isa => 'Int');
  has NextToken => (is => 'ro', isa => 'Str');
  has ScheduledActionNames => (is => 'ro', isa => 'ArrayRef[Str]');
  has StartTime => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeScheduledActions');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::AutoScaling::ScheduledActionsType');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeScheduledActionsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::DescribeScheduledActions - Arguments for method DescribeScheduledActions on Paws::AutoScaling

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeScheduledActions on the 
Auto Scaling service. Use the attributes of this class
as arguments to method DescribeScheduledActions.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeScheduledActions.

As an example:

  $service_obj->DescribeScheduledActions(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AutoScalingGroupName => Str

  

The name of the group.










=head2 EndTime => Str

  

The latest scheduled start time to return. If scheduled action names
are provided, this parameter is ignored.










=head2 MaxRecords => Int

  

The maximum number of items to return with this call.










=head2 NextToken => Str

  

The token for the next set of items to return. (You received this token
from a previous call.)










=head2 ScheduledActionNames => ArrayRef[Str]

  

Describes one or more scheduled actions. If you omit this list, the
call describes all scheduled actions. If you specify an unknown
scheduled action it is ignored with no error.

You can describe up to a maximum of 50 instances with a single call. If
there are more items to return, the call returns a token. To get the
next set of items, repeat the call with the returned token in the
C<NextToken> parameter.










=head2 StartTime => Str

  

The earliest scheduled start time to return. If scheduled action names
are provided, this parameter is ignored.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeScheduledActions in L<Paws::AutoScaling>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

