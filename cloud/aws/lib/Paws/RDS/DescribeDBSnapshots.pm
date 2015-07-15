
package Paws::RDS::DescribeDBSnapshots {
  use Moose;
  has DBInstanceIdentifier => (is => 'ro', isa => 'Str');
  has DBSnapshotIdentifier => (is => 'ro', isa => 'Str');
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::RDS::Filter]');
  has Marker => (is => 'ro', isa => 'Str');
  has MaxRecords => (is => 'ro', isa => 'Int');
  has SnapshotType => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeDBSnapshots');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RDS::DBSnapshotMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeDBSnapshotsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::DescribeDBSnapshots - Arguments for method DescribeDBSnapshots on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeDBSnapshots on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method DescribeDBSnapshots.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeDBSnapshots.

As an example:

  $service_obj->DescribeDBSnapshots(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DBInstanceIdentifier => Str

  

A DB instance identifier to retrieve the list of DB snapshots for.
Cannot be used in conjunction with C<DBSnapshotIdentifier>. This
parameter is not case sensitive.

Constraints:

=over

=item * Must contain from 1 to 63 alphanumeric characters or hyphens

=item * First character must be a letter

=item * Cannot end with a hyphen or contain two consecutive hyphens

=back










=head2 DBSnapshotIdentifier => Str

  

A specific DB snapshot identifier to describe. Cannot be used in
conjunction with C<DBInstanceIdentifier>. This value is stored as a
lowercase string.

Constraints:

=over

=item * Must be 1 to 255 alphanumeric characters

=item * First character must be a letter

=item * Cannot end with a hyphen or contain two consecutive hyphens

=item * If this is the identifier of an automated snapshot, the
C<SnapshotType> parameter must also be specified.

=back










=head2 Filters => ArrayRef[Paws::RDS::Filter]

  

This parameter is not currently supported.










=head2 Marker => Str

  

An optional pagination token provided by a previous
C<DescribeDBSnapshots> request. If this parameter is specified, the
response includes only records beyond the marker, up to the value
specified by C<MaxRecords>.










=head2 MaxRecords => Int

  

The maximum number of records to include in the response. If more
records exist than the specified C<MaxRecords> value, a pagination
token called a marker is included in the response so that the remaining
results may be retrieved.

Default: 100

Constraints: minimum 20, maximum 100










=head2 SnapshotType => Str

  

The type of snapshots that will be returned. Values can be "automated"
or "manual." If not specified, the returned results will include all
snapshots types.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeDBSnapshots in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

