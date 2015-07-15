
package Paws::AutoScaling::DetachLoadBalancers {
  use Moose;
  has AutoScalingGroupName => (is => 'ro', isa => 'Str');
  has LoadBalancerNames => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DetachLoadBalancers');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::AutoScaling::DetachLoadBalancersResultType');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DetachLoadBalancersResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::DetachLoadBalancers - Arguments for method DetachLoadBalancers on Paws::AutoScaling

=head1 DESCRIPTION

This class represents the parameters used for calling the method DetachLoadBalancers on the 
Auto Scaling service. Use the attributes of this class
as arguments to method DetachLoadBalancers.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DetachLoadBalancers.

As an example:

  $service_obj->DetachLoadBalancers(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AutoScalingGroupName => Str

  

The name of the group.










=head2 LoadBalancerNames => ArrayRef[Str]

  

One or more load balancer names.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DetachLoadBalancers in L<Paws::AutoScaling>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

