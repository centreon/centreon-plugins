package Paws::EC2::SpotInstanceStateFault {
  use Moose;
  has Code => (is => 'ro', isa => 'Str', xmlname => 'code', traits => ['Unwrapped']);
  has Message => (is => 'ro', isa => 'Str', xmlname => 'message', traits => ['Unwrapped']);
}
1;
