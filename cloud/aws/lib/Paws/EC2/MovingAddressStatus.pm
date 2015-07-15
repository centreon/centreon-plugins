package Paws::EC2::MovingAddressStatus {
  use Moose;
  has MoveStatus => (is => 'ro', isa => 'Str', xmlname => 'moveStatus', traits => ['Unwrapped']);
  has PublicIp => (is => 'ro', isa => 'Str', xmlname => 'publicIp', traits => ['Unwrapped']);
}
1;
