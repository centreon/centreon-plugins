
package Paws::ELB::CreateAppCookieStickinessPolicy {
  use Moose;
  has CookieName => (is => 'ro', isa => 'Str', required => 1);
  has LoadBalancerName => (is => 'ro', isa => 'Str', required => 1);
  has PolicyName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateAppCookieStickinessPolicy');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ELB::CreateAppCookieStickinessPolicyOutput');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateAppCookieStickinessPolicyResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ELB::CreateAppCookieStickinessPolicy - Arguments for method CreateAppCookieStickinessPolicy on Paws::ELB

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateAppCookieStickinessPolicy on the 
Elastic Load Balancing service. Use the attributes of this class
as arguments to method CreateAppCookieStickinessPolicy.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateAppCookieStickinessPolicy.

As an example:

  $service_obj->CreateAppCookieStickinessPolicy(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> CookieName => Str

  

The name of the application cookie used for stickiness.










=head2 B<REQUIRED> LoadBalancerName => Str

  

The name of the load balancer.










=head2 B<REQUIRED> PolicyName => Str

  

The name of the policy being created. This name must be unique within
the set of policies for this load balancer.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateAppCookieStickinessPolicy in L<Paws::ELB>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

