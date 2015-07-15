
package Paws::RDS::CreateDBSnapshot {
  use Moose;
  has DBInstanceIdentifier => (is => 'ro', isa => 'Str', required => 1);
  has DBSnapshotIdentifier => (is => 'ro', isa => 'Str', required => 1);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::RDS::Tag]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateDBSnapshot');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RDS::CreateDBSnapshotResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateDBSnapshotResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::CreateDBSnapshot - Arguments for method CreateDBSnapshot on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateDBSnapshot on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method CreateDBSnapshot.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateDBSnapshot.

As an example:

  $service_obj->CreateDBSnapshot(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DBInstanceIdentifier => Str

  

The DB instance identifier. This is the unique key that identifies a DB
instance.

Constraints:

=over

=item * Must contain from 1 to 63 alphanumeric characters or hyphens

=item * First character must be a letter

=item * Cannot end with a hyphen or contain two consecutive hyphens

=back










=head2 B<REQUIRED> DBSnapshotIdentifier => Str

  

The identifier for the DB snapshot.

Constraints:

=over

=item * Cannot be null, empty, or blank

=item * Must contain from 1 to 255 alphanumeric characters or hyphens

=item * First character must be a letter

=item * Cannot end with a hyphen or contain two consecutive hyphens

=back

Example: C<my-snapshot-id>










=head2 Tags => ArrayRef[Paws::RDS::Tag]

  



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateDBSnapshot in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

