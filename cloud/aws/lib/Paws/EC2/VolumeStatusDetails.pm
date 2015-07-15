package Paws::EC2::VolumeStatusDetails {
  use Moose;
  has Name => (is => 'ro', isa => 'Str', xmlname => 'name', traits => ['Unwrapped']);
  has Status => (is => 'ro', isa => 'Str', xmlname => 'status', traits => ['Unwrapped']);
}
1;
