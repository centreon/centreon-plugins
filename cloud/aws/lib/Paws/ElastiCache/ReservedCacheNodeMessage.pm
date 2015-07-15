
package Paws::ElastiCache::ReservedCacheNodeMessage {
  use Moose;
  has Marker => (is => 'ro', isa => 'Str');
  has ReservedCacheNodes => (is => 'ro', isa => 'ArrayRef[Paws::ElastiCache::ReservedCacheNode]', xmlname => 'ReservedCacheNode', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::ReservedCacheNodeMessage

=head1 ATTRIBUTES

=head2 Marker => Str

  

Provides an identifier to allow retrieval of paginated results.









=head2 ReservedCacheNodes => ArrayRef[Paws::ElastiCache::ReservedCacheNode]

  

A list of reserved cache nodes. Each element in the list contains
detailed information about one node.











=cut

