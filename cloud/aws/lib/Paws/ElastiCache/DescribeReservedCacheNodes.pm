
package Paws::ElastiCache::DescribeReservedCacheNodes {
  use Moose;
  has CacheNodeType => (is => 'ro', isa => 'Str');
  has Duration => (is => 'ro', isa => 'Str');
  has Marker => (is => 'ro', isa => 'Str');
  has MaxRecords => (is => 'ro', isa => 'Int');
  has OfferingType => (is => 'ro', isa => 'Str');
  has ProductDescription => (is => 'ro', isa => 'Str');
  has ReservedCacheNodeId => (is => 'ro', isa => 'Str');
  has ReservedCacheNodesOfferingId => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeReservedCacheNodes');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::ReservedCacheNodeMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeReservedCacheNodesResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::DescribeReservedCacheNodes - Arguments for method DescribeReservedCacheNodes on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeReservedCacheNodes on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method DescribeReservedCacheNodes.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeReservedCacheNodes.

As an example:

  $service_obj->DescribeReservedCacheNodes(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 CacheNodeType => Str

  

The cache node type filter value. Use this parameter to show only those
reservations matching the specified cache node type.

Valid node types are as follows:

=over

=item * General purpose:

=over

=item * Current generation: C<cache.t2.micro>, C<cache.t2.small>,
C<cache.t2.medium>, C<cache.m3.medium>, C<cache.m3.large>,
C<cache.m3.xlarge>, C<cache.m3.2xlarge>

=item * Previous generation: C<cache.t1.micro>, C<cache.m1.small>,
C<cache.m1.medium>, C<cache.m1.large>, C<cache.m1.xlarge>

=back

=item * Compute optimized: C<cache.c1.xlarge>

=item * Memory optimized

=over

=item * Current generation: C<cache.r3.large>, C<cache.r3.xlarge>,
C<cache.r3.2xlarge>, C<cache.r3.4xlarge>, C<cache.r3.8xlarge>

=item * Previous generation: C<cache.m2.xlarge>, C<cache.m2.2xlarge>,
C<cache.m2.4xlarge>

=back

=back

B<Notes:>

=over

=item * All t2 instances are created in an Amazon Virtual Private Cloud
(VPC).

=item * Redis backup/restore is not supported for t2 instances.

=item * Redis Append-only files (AOF) functionality is not supported
for t1 or t2 instances.

=back

For a complete listing of cache node types and specifications, see
Amazon ElastiCache Product Features and Details and Cache Node
Type-Specific Parameters for Memcached or Cache Node Type-Specific
Parameters for Redis.










=head2 Duration => Str

  

The duration filter value, specified in years or seconds. Use this
parameter to show only reservations for this duration.

Valid Values: C<1 | 3 | 31536000 | 94608000>










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

Default: 100

Constraints: minimum 20; maximum 100.










=head2 OfferingType => Str

  

The offering type filter value. Use this parameter to show only the
available offerings matching the specified offering type.

Valid values: C<"Light Utilization"|"Medium Utilization"|"Heavy
Utilization">










=head2 ProductDescription => Str

  

The product description filter value. Use this parameter to show only
those reservations matching the specified product description.










=head2 ReservedCacheNodeId => Str

  

The reserved cache node identifier filter value. Use this parameter to
show only the reservation that matches the specified reservation ID.










=head2 ReservedCacheNodesOfferingId => Str

  

The offering identifier filter value. Use this parameter to show only
purchased reservations matching the specified offering identifier.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeReservedCacheNodes in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

