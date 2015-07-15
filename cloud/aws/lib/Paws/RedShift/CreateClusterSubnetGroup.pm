
package Paws::RedShift::CreateClusterSubnetGroup {
  use Moose;
  has ClusterSubnetGroupName => (is => 'ro', isa => 'Str', required => 1);
  has Description => (is => 'ro', isa => 'Str', required => 1);
  has SubnetIds => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::Tag]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateClusterSubnetGroup');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RedShift::CreateClusterSubnetGroupResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateClusterSubnetGroupResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::CreateClusterSubnetGroup - Arguments for method CreateClusterSubnetGroup on Paws::RedShift

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateClusterSubnetGroup on the 
Amazon Redshift service. Use the attributes of this class
as arguments to method CreateClusterSubnetGroup.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateClusterSubnetGroup.

As an example:

  $service_obj->CreateClusterSubnetGroup(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ClusterSubnetGroupName => Str

  

The name for the subnet group. Amazon Redshift stores the value as a
lowercase string.

Constraints:

=over

=item * Must contain no more than 255 alphanumeric characters or
hyphens.

=item * Must not be "Default".

=item * Must be unique for all subnet groups that are created by your
AWS account.

=back

Example: C<examplesubnetgroup>










=head2 B<REQUIRED> Description => Str

  

A description for the subnet group.










=head2 B<REQUIRED> SubnetIds => ArrayRef[Str]

  

An array of VPC subnet IDs. A maximum of 20 subnets can be modified in
a single request.










=head2 Tags => ArrayRef[Paws::RedShift::Tag]

  

A list of tag instances.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateClusterSubnetGroup in L<Paws::RedShift>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

