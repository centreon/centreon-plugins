package Paws::ElastiCache::NodeGroupMember {
  use Moose;
  has CacheClusterId => (is => 'ro', isa => 'Str');
  has CacheNodeId => (is => 'ro', isa => 'Str');
  has CurrentRole => (is => 'ro', isa => 'Str');
  has PreferredAvailabilityZone => (is => 'ro', isa => 'Str');
  has ReadEndpoint => (is => 'ro', isa => 'Paws::ElastiCache::Endpoint');
}
1;
