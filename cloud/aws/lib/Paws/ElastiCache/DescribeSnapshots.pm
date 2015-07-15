
package Paws::ElastiCache::DescribeSnapshots {
  use Moose;
  has CacheClusterId => (is => 'ro', isa => 'Str');
  has Marker => (is => 'ro', isa => 'Str');
  has MaxRecords => (is => 'ro', isa => 'Int');
  has SnapshotName => (is => 'ro', isa => 'Str');
  has SnapshotSource => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeSnapshots');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::DescribeSnapshotsListMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeSnapshotsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::DescribeSnapshots - Arguments for method DescribeSnapshots on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeSnapshots on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method DescribeSnapshots.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeSnapshots.

As an example:

  $service_obj->DescribeSnapshots(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 CacheClusterId => Str

  

A user-supplied cluster identifier. If this parameter is specified,
only snapshots associated with that specific cache cluster will be
described.










=head2 Marker => Str

  

An optional marker returned from a prior request. Use this marker for
pagination of results from this action. If this parameter is specified,
the response includes only records beyond the marker, up to the value
specified by I<MaxRecords>.










=head2 MaxRecords => Int

  

The maximum number of records to include in the response. If more
records exist than the specified C<MaxRecords> value, a marker is
included in the response so that the remaining results can be
retrieved.

Default: 50

Constraints: minimum 20; maximum 50.










=head2 SnapshotName => Str

  

A user-supplied name of the snapshot. If this parameter is specified,
only this snapshot will be described.










=head2 SnapshotSource => Str

  

If set to C<system>, the output shows snapshots that were automatically
created by ElastiCache. If set to C<user> the output shows snapshots
that were manually created. If omitted, the output shows both
automatically and manually created snapshots.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeSnapshots in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

