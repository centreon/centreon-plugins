
package Paws::ELB::DeleteLoadBalancerListeners {
  use Moose;
  has LoadBalancerName => (is => 'ro', isa => 'Str', required => 1);
  has LoadBalancerPorts => (is => 'ro', isa => 'ArrayRef[Int]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteLoadBalancerListeners');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ELB::DeleteLoadBalancerListenerOutput');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DeleteLoadBalancerListenersResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ELB::DeleteLoadBalancerListeners - Arguments for method DeleteLoadBalancerListeners on Paws::ELB

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteLoadBalancerListeners on the 
Elastic Load Balancing service. Use the attributes of this class
as arguments to method DeleteLoadBalancerListeners.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteLoadBalancerListeners.

As an example:

  $service_obj->DeleteLoadBalancerListeners(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> LoadBalancerName => Str

  

The name of the load balancer.










=head2 B<REQUIRED> LoadBalancerPorts => ArrayRef[Int]

  

The client port numbers of the listeners.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteLoadBalancerListeners in L<Paws::ELB>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

