package Paws::EC2::SpotInstanceStatus {
  use Moose;
  has Code => (is => 'ro', isa => 'Str', xmlname => 'code', traits => ['Unwrapped']);
  has Message => (is => 'ro', isa => 'Str', xmlname => 'message', traits => ['Unwrapped']);
  has UpdateTime => (is => 'ro', isa => 'Str', xmlname => 'updateTime', traits => ['Unwrapped']);
}
1;
