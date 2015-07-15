package Paws::ElastiCache::CacheSubnetGroup {
  use Moose;
  has CacheSubnetGroupDescription => (is => 'ro', isa => 'Str');
  has CacheSubnetGroupName => (is => 'ro', isa => 'Str');
  has Subnets => (is => 'ro', isa => 'ArrayRef[Paws::ElastiCache::Subnet]');
  has VpcId => (is => 'ro', isa => 'Str');
}
1;
