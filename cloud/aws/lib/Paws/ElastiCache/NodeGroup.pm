package Paws::ElastiCache::NodeGroup {
  use Moose;
  has NodeGroupId => (is => 'ro', isa => 'Str');
  has NodeGroupMembers => (is => 'ro', isa => 'ArrayRef[Paws::ElastiCache::NodeGroupMember]');
  has PrimaryEndpoint => (is => 'ro', isa => 'Paws::ElastiCache::Endpoint');
  has Status => (is => 'ro', isa => 'Str');
}
1;
