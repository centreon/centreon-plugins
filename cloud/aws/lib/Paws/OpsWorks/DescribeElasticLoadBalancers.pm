
package Paws::OpsWorks::DescribeElasticLoadBalancers {
  use Moose;
  has LayerIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has StackId => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeElasticLoadBalancers');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::OpsWorks::DescribeElasticLoadBalancersResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeElasticLoadBalancers - Arguments for method DescribeElasticLoadBalancers on Paws::OpsWorks

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeElasticLoadBalancers on the 
AWS OpsWorks service. Use the attributes of this class
as arguments to method DescribeElasticLoadBalancers.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeElasticLoadBalancers.

As an example:

  $service_obj->DescribeElasticLoadBalancers(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 LayerIds => ArrayRef[Str]

  

A list of layer IDs. The action describes the Elastic Load Balancing
instances for the specified layers.










=head2 StackId => Str

  

A stack ID. The action describes the stack's Elastic Load Balancing
instances.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeElasticLoadBalancers in L<Paws::OpsWorks>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

