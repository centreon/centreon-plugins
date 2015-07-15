
package Paws::AutoScaling::DeleteTags {
  use Moose;
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::AutoScaling::Tag]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteTags');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::DeleteTags - Arguments for method DeleteTags on Paws::AutoScaling

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteTags on the 
Auto Scaling service. Use the attributes of this class
as arguments to method DeleteTags.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteTags.

As an example:

  $service_obj->DeleteTags(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> Tags => ArrayRef[Paws::AutoScaling::Tag]

  

Each tag should be defined by its resource type, resource ID, key,
value, and a propagate flag. Valid values are: Resource type =
I<auto-scaling-group>, Resource ID = I<AutoScalingGroupName>,
key=I<value>, value=I<value>, propagate=I<true> or I<false>.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteTags in L<Paws::AutoScaling>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

