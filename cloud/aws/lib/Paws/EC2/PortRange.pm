package Paws::EC2::PortRange {
  use Moose;
  has From => (is => 'ro', isa => 'Int', xmlname => 'from', traits => ['Unwrapped']);
  has To => (is => 'ro', isa => 'Int', xmlname => 'to', traits => ['Unwrapped']);
}
1;
