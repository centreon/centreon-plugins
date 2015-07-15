package Paws::EC2::IcmpTypeCode {
  use Moose;
  has Code => (is => 'ro', isa => 'Int', xmlname => 'code', traits => ['Unwrapped']);
  has Type => (is => 'ro', isa => 'Int', xmlname => 'type', traits => ['Unwrapped']);
}
1;
