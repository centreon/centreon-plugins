package Paws::ElastiCache::Subnet {
  use Moose;
  has SubnetAvailabilityZone => (is => 'ro', isa => 'Paws::ElastiCache::AvailabilityZone');
  has SubnetIdentifier => (is => 'ro', isa => 'Str');
}
1;
