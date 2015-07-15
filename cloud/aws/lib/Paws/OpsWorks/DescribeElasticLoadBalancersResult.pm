
package Paws::OpsWorks::DescribeElasticLoadBalancersResult {
  use Moose;
  has ElasticLoadBalancers => (is => 'ro', isa => 'ArrayRef[Paws::OpsWorks::ElasticLoadBalancer]');

}

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeElasticLoadBalancersResult

=head1 ATTRIBUTES

=head2 ElasticLoadBalancers => ArrayRef[Paws::OpsWorks::ElasticLoadBalancer]

  

A list of C<ElasticLoadBalancer> objects that describe the specified
Elastic Load Balancing instances.











=cut

1;