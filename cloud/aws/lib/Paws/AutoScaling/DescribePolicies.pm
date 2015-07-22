
package Paws::AutoScaling::DescribePolicies {
  use Moose;
  has AutoScalingGroupName => (is => 'ro', isa => 'Str');
  has MaxRecords => (is => 'ro', isa => 'Int');
  has NextToken => (is => 'ro', isa => 'Str');
  has PolicyNames => (is => 'ro', isa => 'ArrayRef[Str]');
  has PolicyTypes => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribePolicies');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::AutoScaling::PoliciesType');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribePoliciesResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::DescribePolicies - Arguments for method DescribePolicies on Paws::AutoScaling

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribePolicies on the 
Auto Scaling service. Use the attributes of this class
as arguments to method DescribePolicies.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribePolicies.

As an example:

  $service_obj->DescribePolicies(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AutoScalingGroupName => Str

  

The name of the group.










=head2 MaxRecords => Int

  

The maximum number of items to be returned with each call.










=head2 NextToken => Str

  

The token for the next set of items to return. (You received this token
from a previous call.)










=head2 PolicyNames => ArrayRef[Str]

  

One or more policy names or policy ARNs to be described. If you omit
this list, all policy names are described. If an group name is
provided, the results are limited to that group. This list is limited
to 50 items. If you specify an unknown policy name, it is ignored with
no error.










=head2 PolicyTypes => ArrayRef[Str]

  

One or more policy types. Valid values are C<SimpleScaling> and
C<StepScaling>.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribePolicies in L<Paws::AutoScaling>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

