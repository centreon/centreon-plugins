
package Paws::RDS::CreateDBSubnetGroup {
  use Moose;
  has DBSubnetGroupDescription => (is => 'ro', isa => 'Str', required => 1);
  has DBSubnetGroupName => (is => 'ro', isa => 'Str', required => 1);
  has SubnetIds => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::RDS::Tag]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateDBSubnetGroup');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RDS::CreateDBSubnetGroupResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateDBSubnetGroupResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::CreateDBSubnetGroup - Arguments for method CreateDBSubnetGroup on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateDBSubnetGroup on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method CreateDBSubnetGroup.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateDBSubnetGroup.

As an example:

  $service_obj->CreateDBSubnetGroup(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DBSubnetGroupDescription => Str

  

The description for the DB subnet group.










=head2 B<REQUIRED> DBSubnetGroupName => Str

  

The name for the DB subnet group. This value is stored as a lowercase
string.

Constraints: Must contain no more than 255 alphanumeric characters or
hyphens. Must not be "Default".

Example: C<mySubnetgroup>










=head2 B<REQUIRED> SubnetIds => ArrayRef[Str]

  

The EC2 Subnet IDs for the DB subnet group.










=head2 Tags => ArrayRef[Paws::RDS::Tag]

  



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateDBSubnetGroup in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

