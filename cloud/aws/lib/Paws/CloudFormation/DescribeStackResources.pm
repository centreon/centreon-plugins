
package Paws::CloudFormation::DescribeStackResources {
  use Moose;
  has LogicalResourceId => (is => 'ro', isa => 'Str');
  has PhysicalResourceId => (is => 'ro', isa => 'Str');
  has StackName => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeStackResources');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudFormation::DescribeStackResourcesOutput');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeStackResourcesResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudFormation::DescribeStackResources - Arguments for method DescribeStackResources on Paws::CloudFormation

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeStackResources on the 
AWS CloudFormation service. Use the attributes of this class
as arguments to method DescribeStackResources.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeStackResources.

As an example:

  $service_obj->DescribeStackResources(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 LogicalResourceId => Str

  

The logical name of the resource as specified in the template.

Default: There is no default value.










=head2 PhysicalResourceId => Str

  

The name or unique identifier that corresponds to a physical instance
ID of a resource supported by AWS CloudFormation.

For example, for an Amazon Elastic Compute Cloud (EC2) instance,
C<PhysicalResourceId> corresponds to the C<InstanceId>. You can pass
the EC2 C<InstanceId> to C<DescribeStackResources> to find which stack
the instance belongs to and what other resources are part of the stack.

Required: Conditional. If you do not specify C<PhysicalResourceId>, you
must specify C<StackName>.

Default: There is no default value.










=head2 StackName => Str

  

The name or the unique stack ID that is associated with the stack,
which are not always interchangeable:

=over

=item * Running stacks: You can specify either the stack's name or its
unique stack ID.

=item * Deleted stacks: You must specify the unique stack ID.

=back

Default: There is no default value.

Required: Conditional. If you do not specify C<StackName>, you must
specify C<PhysicalResourceId>.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeStackResources in L<Paws::CloudFormation>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

