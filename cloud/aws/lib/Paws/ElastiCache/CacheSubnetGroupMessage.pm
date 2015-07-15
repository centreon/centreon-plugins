
package Paws::ElastiCache::CacheSubnetGroupMessage {
  use Moose;
  has CacheSubnetGroups => (is => 'ro', isa => 'ArrayRef[Paws::ElastiCache::CacheSubnetGroup]', xmlname => 'CacheSubnetGroup', traits => ['Unwrapped',]);
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::CacheSubnetGroupMessage

=head1 ATTRIBUTES

=head2 CacheSubnetGroups => ArrayRef[Paws::ElastiCache::CacheSubnetGroup]

  

A list of cache subnet groups. Each element in the list contains
detailed information about one group.









=head2 Marker => Str

  

Provides an identifier to allow retrieval of paginated results.











=cut

