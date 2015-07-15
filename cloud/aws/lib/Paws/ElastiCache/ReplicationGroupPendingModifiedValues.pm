package Paws::ElastiCache::ReplicationGroupPendingModifiedValues {
  use Moose;
  has AutomaticFailoverStatus => (is => 'ro', isa => 'Str');
  has PrimaryClusterId => (is => 'ro', isa => 'Str');
}
1;
