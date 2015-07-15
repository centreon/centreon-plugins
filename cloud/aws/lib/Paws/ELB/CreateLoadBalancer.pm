
package Paws::ELB::CreateLoadBalancer {
  use Moose;
  has AvailabilityZones => (is => 'ro', isa => 'ArrayRef[Str]');
  has Listeners => (is => 'ro', isa => 'ArrayRef[Paws::ELB::Listener]', required => 1);
  has LoadBalancerName => (is => 'ro', isa => 'Str', required => 1);
  has Scheme => (is => 'ro', isa => 'Str');
  has SecurityGroups => (is => 'ro', isa => 'ArrayRef[Str]');
  has Subnets => (is => 'ro', isa => 'ArrayRef[Str]');
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::ELB::Tag]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateLoadBalancer');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ELB::CreateAccessPointOutput');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateLoadBalancerResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ELB::CreateLoadBalancer - Arguments for method CreateLoadBalancer on Paws::ELB

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateLoadBalancer on the 
Elastic Load Balancing service. Use the attributes of this class
as arguments to method CreateLoadBalancer.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateLoadBalancer.

As an example:

  $service_obj->CreateLoadBalancer(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AvailabilityZones => ArrayRef[Str]

  

One or more Availability Zones from the same region as the load
balancer. Traffic is equally distributed across all specified
Availability Zones.

You must specify at least one Availability Zone.

You can add more Availability Zones after you create the load balancer
using EnableAvailabilityZonesForLoadBalancer.










=head2 B<REQUIRED> Listeners => ArrayRef[Paws::ELB::Listener]

  

The listeners.

For more information, see Listeners for Your Load Balancer in the
I<Elastic Load Balancing Developer Guide>.










=head2 B<REQUIRED> LoadBalancerName => Str

  

The name of the load balancer.

This name must be unique within your AWS account, must have a maximum
of 32 characters, must contain only alphanumeric characters or hyphens,
and cannot begin or end with a hyphen.










=head2 Scheme => Str

  

The type of a load balancer. Valid only for load balancers in a VPC.

By default, Elastic Load Balancing creates an Internet-facing load
balancer with a publicly resolvable DNS name, which resolves to public
IP addresses. For more information about Internet-facing and Internal
load balancers, see Internet-facing and Internal Load Balancers in the
I<Elastic Load Balancing Developer Guide>.

Specify C<internal> to create an internal load balancer with a DNS name
that resolves to private IP addresses.










=head2 SecurityGroups => ArrayRef[Str]

  

The IDs of the security groups to assign to the load balancer.










=head2 Subnets => ArrayRef[Str]

  

The IDs of the subnets in your VPC to attach to the load balancer.
Specify one subnet per Availability Zone specified in
C<AvailabilityZones>.










=head2 Tags => ArrayRef[Paws::ELB::Tag]

  

A list of tags to assign to the load balancer.

For more information about tagging your load balancer, see Tagging in
the I<Elastic Load Balancing Developer Guide>.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateLoadBalancer in L<Paws::ELB>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

