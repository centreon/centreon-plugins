package Paws::EC2::ReservedInstancesId {
  use Moose;
  has ReservedInstancesId => (is => 'ro', isa => 'Str', xmlname => 'reservedInstancesId', traits => ['Unwrapped']);
}
1;
