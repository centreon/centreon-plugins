
package Paws::ElastiCache::CacheSecurityGroupMessage {
  use Moose;
  has CacheSecurityGroups => (is => 'ro', isa => 'ArrayRef[Paws::ElastiCache::CacheSecurityGroup]', xmlname => 'CacheSecurityGroup', traits => ['Unwrapped',]);
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::CacheSecurityGroupMessage

=head1 ATTRIBUTES

=head2 CacheSecurityGroups => ArrayRef[Paws::ElastiCache::CacheSecurityGroup]

  

A list of cache security groups. Each element in the list contains
detailed information about one group.









=head2 Marker => Str

  

Provides an identifier to allow retrieval of paginated results.











=cut

