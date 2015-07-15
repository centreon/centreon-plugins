package Paws::ElastiCache::ParameterNameValue {
  use Moose;
  has ParameterName => (is => 'ro', isa => 'Str');
  has ParameterValue => (is => 'ro', isa => 'Str');
}
1;
