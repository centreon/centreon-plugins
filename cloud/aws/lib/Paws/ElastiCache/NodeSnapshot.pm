package Paws::ElastiCache::NodeSnapshot {
  use Moose;
  has CacheNodeCreateTime => (is => 'ro', isa => 'Str');
  has CacheNodeId => (is => 'ro', isa => 'Str');
  has CacheSize => (is => 'ro', isa => 'Str');
  has SnapshotCreateTime => (is => 'ro', isa => 'Str');
}
1;
