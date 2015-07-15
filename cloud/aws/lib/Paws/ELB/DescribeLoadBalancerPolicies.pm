
package Paws::ELB::DescribeLoadBalancerPolicies {
  use Moose;
  has LoadBalancerName => (is => 'ro', isa => 'Str');
  has PolicyNames => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeLoadBalancerPolicies');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ELB::DescribeLoadBalancerPoliciesOutput');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeLoadBalancerPoliciesResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ELB::DescribeLoadBalancerPolicies - Arguments for method DescribeLoadBalancerPolicies on Paws::ELB

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeLoadBalancerPolicies on the 
Elastic Load Balancing service. Use the attributes of this class
as arguments to method DescribeLoadBalancerPolicies.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeLoadBalancerPolicies.

As an example:

  $service_obj->DescribeLoadBalancerPolicies(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 LoadBalancerName => Str

  

The name of the load balancer.










=head2 PolicyNames => ArrayRef[Str]

  

The names of the policies.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeLoadBalancerPolicies in L<Paws::ELB>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

