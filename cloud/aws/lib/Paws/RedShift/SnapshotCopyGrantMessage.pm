
package Paws::RedShift::SnapshotCopyGrantMessage {
  use Moose;
  has Marker => (is => 'ro', isa => 'Str');
  has SnapshotCopyGrants => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::SnapshotCopyGrant]', xmlname => 'SnapshotCopyGrant', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::SnapshotCopyGrantMessage

=head1 ATTRIBUTES

=head2 Marker => Str

  

An optional parameter that specifies the starting point to return a set
of response records. When the results of a C<DescribeSnapshotCopyGrant>
request exceed the value specified in C<MaxRecords>, AWS returns a
value in the C<Marker> field of the response. You can retrieve the next
set of response records by providing the returned marker value in the
C<Marker> parameter and retrying the request.

Constraints: You can specify either the B<SnapshotCopyGrantName>
parameter or the B<Marker> parameter, but not both.









=head2 SnapshotCopyGrants => ArrayRef[Paws::RedShift::SnapshotCopyGrant]

  

The list of snapshot copy grants.











=cut

