package Paws::ElastiCache::CacheSecurityGroupMembership {
  use Moose;
  has CacheSecurityGroupName => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Str');
}
1;
