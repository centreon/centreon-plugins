package Paws::EC2::InstanceState {
  use Moose;
  has Code => (is => 'ro', isa => 'Int', xmlname => 'code', traits => ['Unwrapped']);
  has Name => (is => 'ro', isa => 'Str', xmlname => 'name', traits => ['Unwrapped']);
}
1;
