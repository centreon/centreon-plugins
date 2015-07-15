package Paws::ElastiCache::EngineDefaults {
  use Moose;
  has CacheNodeTypeSpecificParameters => (is => 'ro', isa => 'ArrayRef[Paws::ElastiCache::CacheNodeTypeSpecificParameter]');
  has CacheParameterGroupFamily => (is => 'ro', isa => 'Str');
  has Marker => (is => 'ro', isa => 'Str');
  has Parameters => (is => 'ro', isa => 'ArrayRef[Paws::ElastiCache::Parameter]');
}
1;
