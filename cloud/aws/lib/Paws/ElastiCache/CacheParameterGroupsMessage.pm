
package Paws::ElastiCache::CacheParameterGroupsMessage {
  use Moose;
  has CacheParameterGroups => (is => 'ro', isa => 'ArrayRef[Paws::ElastiCache::CacheParameterGroup]', xmlname => 'CacheParameterGroup', traits => ['Unwrapped',]);
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::CacheParameterGroupsMessage

=head1 ATTRIBUTES

=head2 CacheParameterGroups => ArrayRef[Paws::ElastiCache::CacheParameterGroup]

  

A list of cache parameter groups. Each element in the list contains
detailed information about one cache parameter group.









=head2 Marker => Str

  

Provides an identifier to allow retrieval of paginated results.











=cut

