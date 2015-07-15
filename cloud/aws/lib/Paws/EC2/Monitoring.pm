package Paws::EC2::Monitoring {
  use Moose;
  has State => (is => 'ro', isa => 'Str', xmlname => 'state', traits => ['Unwrapped']);
}
1;
