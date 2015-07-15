
package Paws::ELB::ModifyLoadBalancerAttributes {
  use Moose;
  has LoadBalancerAttributes => (is => 'ro', isa => 'Paws::ELB::LoadBalancerAttributes', required => 1);
  has LoadBalancerName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifyLoadBalancerAttributes');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ELB::ModifyLoadBalancerAttributesOutput');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ModifyLoadBalancerAttributesResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ELB::ModifyLoadBalancerAttributes - Arguments for method ModifyLoadBalancerAttributes on Paws::ELB

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifyLoadBalancerAttributes on the 
Elastic Load Balancing service. Use the attributes of this class
as arguments to method ModifyLoadBalancerAttributes.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifyLoadBalancerAttributes.

As an example:

  $service_obj->ModifyLoadBalancerAttributes(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> LoadBalancerAttributes => Paws::ELB::LoadBalancerAttributes

  

The attributes of the load balancer.










=head2 B<REQUIRED> LoadBalancerName => Str

  

The name of the load balancer.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifyLoadBalancerAttributes in L<Paws::ELB>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

