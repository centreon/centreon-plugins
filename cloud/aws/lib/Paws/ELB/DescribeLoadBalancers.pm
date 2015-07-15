
package Paws::ELB::DescribeLoadBalancers {
  use Moose;
  has LoadBalancerNames => (is => 'ro', isa => 'ArrayRef[Str]');
  has Marker => (is => 'ro', isa => 'Str');
  has PageSize => (is => 'ro', isa => 'Int');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeLoadBalancers');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ELB::DescribeAccessPointsOutput');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeLoadBalancersResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ELB::DescribeLoadBalancers - Arguments for method DescribeLoadBalancers on Paws::ELB

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeLoadBalancers on the 
Elastic Load Balancing service. Use the attributes of this class
as arguments to method DescribeLoadBalancers.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeLoadBalancers.

As an example:

  $service_obj->DescribeLoadBalancers(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 LoadBalancerNames => ArrayRef[Str]

  

The names of the load balancers.










=head2 Marker => Str

  

The marker for the next set of results. (You received this marker from
a previous call.)










=head2 PageSize => Int

  

The maximum number of results to return with this call (a number from 1
to 400). The default is 400.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeLoadBalancers in L<Paws::ELB>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

