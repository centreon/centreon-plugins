
package Paws::AutoScaling::DescribeScalingActivities {
  use Moose;
  has ActivityIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has AutoScalingGroupName => (is => 'ro', isa => 'Str');
  has MaxRecords => (is => 'ro', isa => 'Int');
  has NextToken => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeScalingActivities');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::AutoScaling::ActivitiesType');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeScalingActivitiesResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::DescribeScalingActivities - Arguments for method DescribeScalingActivities on Paws::AutoScaling

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeScalingActivities on the 
Auto Scaling service. Use the attributes of this class
as arguments to method DescribeScalingActivities.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeScalingActivities.

As an example:

  $service_obj->DescribeScalingActivities(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ActivityIds => ArrayRef[Str]

  

A list containing the activity IDs of the desired scaling activities.
If this list is omitted, all activities are described. If an
C<AutoScalingGroupName> is provided, the results are limited to that
group. The list of requested activities cannot contain more than 50
items. If unknown activities are requested, they are ignored with no
error.










=head2 AutoScalingGroupName => Str

  

The name of the group.










=head2 MaxRecords => Int

  

The maximum number of items to return with this call.










=head2 NextToken => Str

  

The token for the next set of items to return. (You received this token
from a previous call.)












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeScalingActivities in L<Paws::AutoScaling>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

