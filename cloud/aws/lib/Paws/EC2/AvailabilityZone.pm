package Paws::EC2::AvailabilityZone {
  use Moose;
  has Messages => (is => 'ro', isa => 'ArrayRef[Paws::EC2::AvailabilityZoneMessage]', xmlname => 'messageSet', traits => ['Unwrapped']);
  has RegionName => (is => 'ro', isa => 'Str', xmlname => 'regionName', traits => ['Unwrapped']);
  has State => (is => 'ro', isa => 'Str', xmlname => 'zoneState', traits => ['Unwrapped']);
  has ZoneName => (is => 'ro', isa => 'Str', xmlname => 'zoneName', traits => ['Unwrapped']);
}
1;
