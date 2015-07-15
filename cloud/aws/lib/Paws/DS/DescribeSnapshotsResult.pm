
package Paws::DS::DescribeSnapshotsResult {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str');
  has Snapshots => (is => 'ro', isa => 'ArrayRef[Paws::DS::Snapshot]');

}

### main pod documentation begin ###

=head1 NAME

Paws::DS::DescribeSnapshotsResult

=head1 ATTRIBUTES

=head2 NextToken => Str

  

If not null, more results are available. Pass this value in the
I<NextToken> member of a subsequent call to DescribeSnapshots.









=head2 Snapshots => ArrayRef[Paws::DS::Snapshot]

  

The list of Snapshot objects that were retrieved.

It is possible that this list contains less than the number of items
specified in the I<Limit> member of the request. This occurs if there
are less than the requested number of items left to retrieve, or if the
limitations of the operation have been exceeded.











=cut

1;