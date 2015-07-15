package Paws::ElastiCache::SecurityGroupMembership {
  use Moose;
  has SecurityGroupId => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Str');
}
1;
