
package Paws::ECS::DescribeClusters {
  use Moose;
  has clusters => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeClusters');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ECS::DescribeClustersResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ECS::DescribeClusters - Arguments for method DescribeClusters on Paws::ECS

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeClusters on the 
Amazon EC2 Container Service service. Use the attributes of this class
as arguments to method DescribeClusters.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeClusters.

As an example:

  $service_obj->DescribeClusters(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 clusters => ArrayRef[Str]

  

A space-separated list of cluster names or full cluster Amazon Resource
Name (ARN) entries. If you do not specify a cluster, the default
cluster is assumed.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeClusters in L<Paws::ECS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

