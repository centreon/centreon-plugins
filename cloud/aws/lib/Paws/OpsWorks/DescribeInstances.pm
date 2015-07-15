
package Paws::OpsWorks::DescribeInstances {
  use Moose;
  has InstanceIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has LayerId => (is => 'ro', isa => 'Str');
  has StackId => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeInstances');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::OpsWorks::DescribeInstancesResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeInstances - Arguments for method DescribeInstances on Paws::OpsWorks

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeInstances on the 
AWS OpsWorks service. Use the attributes of this class
as arguments to method DescribeInstances.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeInstances.

As an example:

  $service_obj->DescribeInstances(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 InstanceIds => ArrayRef[Str]

  

An array of instance IDs to be described. If you use this parameter,
C<DescribeInstances> returns a description of the specified instances.
Otherwise, it returns a description of every instance.










=head2 LayerId => Str

  

A layer ID. If you use this parameter, C<DescribeInstances> returns
descriptions of the instances associated with the specified layer.










=head2 StackId => Str

  

A stack ID. If you use this parameter, C<DescribeInstances> returns
descriptions of the instances associated with the specified stack.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeInstances in L<Paws::OpsWorks>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

