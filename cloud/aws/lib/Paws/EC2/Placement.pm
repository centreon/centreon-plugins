package Paws::EC2::Placement {
  use Moose;
  has AvailabilityZone => (is => 'ro', isa => 'Str', xmlname => 'availabilityZone', traits => ['Unwrapped']);
  has GroupName => (is => 'ro', isa => 'Str', xmlname => 'groupName', traits => ['Unwrapped']);
  has Tenancy => (is => 'ro', isa => 'Str', xmlname => 'tenancy', traits => ['Unwrapped']);
}
1;
