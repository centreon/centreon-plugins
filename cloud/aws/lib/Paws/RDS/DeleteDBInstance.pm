
package Paws::RDS::DeleteDBInstance {
  use Moose;
  has DBInstanceIdentifier => (is => 'ro', isa => 'Str', required => 1);
  has FinalDBSnapshotIdentifier => (is => 'ro', isa => 'Str');
  has SkipFinalSnapshot => (is => 'ro', isa => 'Bool');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteDBInstance');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RDS::DeleteDBInstanceResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DeleteDBInstanceResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::DeleteDBInstance - Arguments for method DeleteDBInstance on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteDBInstance on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method DeleteDBInstance.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteDBInstance.

As an example:

  $service_obj->DeleteDBInstance(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DBInstanceIdentifier => Str

  

The DB instance identifier for the DB instance to be deleted. This
parameter isn't case sensitive.

Constraints:

=over

=item * Must contain from 1 to 63 alphanumeric characters or hyphens

=item * First character must be a letter

=item * Cannot end with a hyphen or contain two consecutive hyphens

=back










=head2 FinalDBSnapshotIdentifier => Str

  

The DBSnapshotIdentifier of the new DBSnapshot created when
SkipFinalSnapshot is set to C<false>.

Specifying this parameter and also setting the SkipFinalShapshot
parameter to true results in an error.

Constraints:

=over

=item * Must be 1 to 255 alphanumeric characters

=item * First character must be a letter

=item * Cannot end with a hyphen or contain two consecutive hyphens

=item * Cannot be specified when deleting a Read Replica.

=back










=head2 SkipFinalSnapshot => Bool

  

Determines whether a final DB snapshot is created before the DB
instance is deleted. If C<true> is specified, no DBSnapshot is created.
If C<false> is specified, a DB snapshot is created before the DB
instance is deleted.

Specify C<true> when deleting a Read Replica.

The FinalDBSnapshotIdentifier parameter must be specified if
SkipFinalSnapshot is C<false>.

Default: C<false>












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteDBInstance in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

