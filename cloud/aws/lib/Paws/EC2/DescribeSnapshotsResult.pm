
package Paws::EC2::DescribeSnapshotsResult {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str', xmlname => 'nextToken', traits => ['Unwrapped',]);
  has Snapshots => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Snapshot]', xmlname => 'snapshotSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeSnapshotsResult

=head1 ATTRIBUTES

=head2 NextToken => Str

  

The C<NextToken> value to include in a future C<DescribeSnapshots>
request. When the results of a C<DescribeSnapshots> request exceed
C<MaxResults>, this value can be used to retrieve the next page of
results. This value is C<null> when there are no more results to
return.









=head2 Snapshots => ArrayRef[Paws::EC2::Snapshot]

  

Information about the snapshots.











=cut

