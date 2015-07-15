package Paws::EC2::Region {
  use Moose;
  has Endpoint => (is => 'ro', isa => 'Str', xmlname => 'regionEndpoint', traits => ['Unwrapped']);
  has RegionName => (is => 'ro', isa => 'Str', xmlname => 'regionName', traits => ['Unwrapped']);
}
1;
