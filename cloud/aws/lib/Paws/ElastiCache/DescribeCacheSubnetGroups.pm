
package Paws::ElastiCache::DescribeCacheSubnetGroups {
  use Moose;
  has CacheSubnetGroupName => (is => 'ro', isa => 'Str');
  has Marker => (is => 'ro', isa => 'Str');
  has MaxRecords => (is => 'ro', isa => 'Int');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeCacheSubnetGroups');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::CacheSubnetGroupMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeCacheSubnetGroupsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::DescribeCacheSubnetGroups - Arguments for method DescribeCacheSubnetGroups on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeCacheSubnetGroups on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method DescribeCacheSubnetGroups.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeCacheSubnetGroups.

As an example:

  $service_obj->DescribeCacheSubnetGroups(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 CacheSubnetGroupName => Str

  

The name of the cache subnet group to return details for.










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












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeCacheSubnetGroups in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

