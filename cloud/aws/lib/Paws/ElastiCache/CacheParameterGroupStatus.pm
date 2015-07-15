package Paws::ElastiCache::CacheParameterGroupStatus {
  use Moose;
  has CacheNodeIdsToReboot => (is => 'ro', isa => 'ArrayRef[Str]');
  has CacheParameterGroupName => (is => 'ro', isa => 'Str');
  has ParameterApplyStatus => (is => 'ro', isa => 'Str');
}
1;
