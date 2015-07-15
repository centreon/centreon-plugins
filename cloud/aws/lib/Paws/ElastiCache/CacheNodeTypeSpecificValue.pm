package Paws::ElastiCache::CacheNodeTypeSpecificValue {
  use Moose;
  has CacheNodeType => (is => 'ro', isa => 'Str');
  has Value => (is => 'ro', isa => 'Str');
}
1;
