package Paws::RDS::Subnet {
  use Moose;
  has SubnetAvailabilityZone => (is => 'ro', isa => 'Paws::RDS::AvailabilityZone');
  has SubnetIdentifier => (is => 'ro', isa => 'Str');
  has SubnetStatus => (is => 'ro', isa => 'Str');
}
1;
