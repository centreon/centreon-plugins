
package Paws::ElastiCache::DescribeCacheClusters {
  use Moose;
  has CacheClusterId => (is => 'ro', isa => 'Str');
  has Marker => (is => 'ro', isa => 'Str');
  has MaxRecords => (is => 'ro', isa => 'Int');
  has ShowCacheNodeInfo => (is => 'ro', isa => 'Bool');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeCacheClusters');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::CacheClusterMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeCacheClustersResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::DescribeCacheClusters - Arguments for method DescribeCacheClusters on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeCacheClusters on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method DescribeCacheClusters.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeCacheClusters.

As an example:

  $service_obj->DescribeCacheClusters(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 CacheClusterId => Str

  

The user-supplied cluster identifier. If this parameter is specified,
only information about that specific cache cluster is returned. This
parameter isn't case sensitive.










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










=head2 ShowCacheNodeInfo => Bool

  

An optional flag that can be included in the DescribeCacheCluster
request to retrieve information about the individual cache nodes.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeCacheClusters in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

