package Paws::ElastiCache::ReplicationGroup {
  use Moose;
  has AutomaticFailover => (is => 'ro', isa => 'Str');
  has Description => (is => 'ro', isa => 'Str');
  has MemberClusters => (is => 'ro', isa => 'ArrayRef[Str]');
  has NodeGroups => (is => 'ro', isa => 'ArrayRef[Paws::ElastiCache::NodeGroup]');
  has PendingModifiedValues => (is => 'ro', isa => 'Paws::ElastiCache::ReplicationGroupPendingModifiedValues');
  has ReplicationGroupId => (is => 'ro', isa => 'Str');
  has SnapshottingClusterId => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Str');
}
1;
