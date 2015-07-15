
package Paws::ElastiCache::ReservedCacheNodesOfferingMessage {
  use Moose;
  has Marker => (is => 'ro', isa => 'Str');
  has ReservedCacheNodesOfferings => (is => 'ro', isa => 'ArrayRef[Paws::ElastiCache::ReservedCacheNodesOffering]', xmlname => 'ReservedCacheNodesOffering', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::ReservedCacheNodesOfferingMessage

=head1 ATTRIBUTES

=head2 Marker => Str

  

Provides an identifier to allow retrieval of paginated results.









=head2 ReservedCacheNodesOfferings => ArrayRef[Paws::ElastiCache::ReservedCacheNodesOffering]

  

A list of reserved cache node offerings. Each element in the list
contains detailed information about one offering.











=cut

