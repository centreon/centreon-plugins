
package Paws::OpsWorks::DescribeRdsDbInstances {
  use Moose;
  has RdsDbInstanceArns => (is => 'ro', isa => 'ArrayRef[Str]');
  has StackId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeRdsDbInstances');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::OpsWorks::DescribeRdsDbInstancesResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeRdsDbInstances - Arguments for method DescribeRdsDbInstances on Paws::OpsWorks

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeRdsDbInstances on the 
AWS OpsWorks service. Use the attributes of this class
as arguments to method DescribeRdsDbInstances.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeRdsDbInstances.

As an example:

  $service_obj->DescribeRdsDbInstances(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 RdsDbInstanceArns => ArrayRef[Str]

  

An array containing the ARNs of the instances to be described.










=head2 B<REQUIRED> StackId => Str

  

The stack ID that the instances are registered with. The operation
returns descriptions of all registered Amazon RDS instances.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeRdsDbInstances in L<Paws::OpsWorks>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

