
package Paws::ElastiCache::DescribeSnapshotsListMessage {
  use Moose;
  has Marker => (is => 'ro', isa => 'Str');
  has Snapshots => (is => 'ro', isa => 'ArrayRef[Paws::ElastiCache::Snapshot]', xmlname => 'Snapshot', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::DescribeSnapshotsListMessage

=head1 ATTRIBUTES

=head2 Marker => Str

  

An optional marker returned from a prior request. Use this marker for
pagination of results from this action. If this parameter is specified,
the response includes only records beyond the marker, up to the value
specified by I<MaxRecords>.









=head2 Snapshots => ArrayRef[Paws::ElastiCache::Snapshot]

  

A list of snapshots. Each item in the list contains detailed
information about one snapshot.











=cut

