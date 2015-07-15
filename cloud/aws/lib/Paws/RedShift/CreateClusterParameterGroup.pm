
package Paws::RedShift::CreateClusterParameterGroup {
  use Moose;
  has Description => (is => 'ro', isa => 'Str', required => 1);
  has ParameterGroupFamily => (is => 'ro', isa => 'Str', required => 1);
  has ParameterGroupName => (is => 'ro', isa => 'Str', required => 1);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::Tag]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateClusterParameterGroup');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RedShift::CreateClusterParameterGroupResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateClusterParameterGroupResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::CreateClusterParameterGroup - Arguments for method CreateClusterParameterGroup on Paws::RedShift

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateClusterParameterGroup on the 
Amazon Redshift service. Use the attributes of this class
as arguments to method CreateClusterParameterGroup.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateClusterParameterGroup.

As an example:

  $service_obj->CreateClusterParameterGroup(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> Description => Str

  

A description of the parameter group.










=head2 B<REQUIRED> ParameterGroupFamily => Str

  

The Amazon Redshift engine version to which the cluster parameter group
applies. The cluster engine version determines the set of parameters.

To get a list of valid parameter group family names, you can call
DescribeClusterParameterGroups. By default, Amazon Redshift returns a
list of all the parameter groups that are owned by your AWS account,
including the default parameter groups for each Amazon Redshift engine
version. The parameter group family names associated with the default
parameter groups provide you the valid values. For example, a valid
family name is "redshift-1.0".










=head2 B<REQUIRED> ParameterGroupName => Str

  

The name of the cluster parameter group.

Constraints:

=over

=item * Must be 1 to 255 alphanumeric characters or hyphens

=item * First character must be a letter.

=item * Cannot end with a hyphen or contain two consecutive hyphens.

=item * Must be unique withing your AWS account.

=back

This value is stored as a lower-case string.










=head2 Tags => ArrayRef[Paws::RedShift::Tag]

  

A list of tag instances.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateClusterParameterGroup in L<Paws::RedShift>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

