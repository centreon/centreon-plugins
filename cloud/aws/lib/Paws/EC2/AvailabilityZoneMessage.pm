package Paws::EC2::AvailabilityZoneMessage {
  use Moose;
  has Message => (is => 'ro', isa => 'Str', xmlname => 'message', traits => ['Unwrapped']);
}
1;
