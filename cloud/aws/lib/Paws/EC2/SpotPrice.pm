package Paws::EC2::SpotPrice {
  use Moose;
  has AvailabilityZone => (is => 'ro', isa => 'Str', xmlname => 'availabilityZone', traits => ['Unwrapped']);
  has InstanceType => (is => 'ro', isa => 'Str', xmlname => 'instanceType', traits => ['Unwrapped']);
  has ProductDescription => (is => 'ro', isa => 'Str', xmlname => 'productDescription', traits => ['Unwrapped']);
  has SpotPrice => (is => 'ro', isa => 'Str', xmlname => 'spotPrice', traits => ['Unwrapped']);
  has Timestamp => (is => 'ro', isa => 'Str', xmlname => 'timestamp', traits => ['Unwrapped']);
}
1;
