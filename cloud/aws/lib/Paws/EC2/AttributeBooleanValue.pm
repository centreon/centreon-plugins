package Paws::EC2::AttributeBooleanValue {
  use Moose;
  has Value => (is => 'ro', isa => 'Bool', xmlname => 'value', traits => ['Unwrapped']);
}
1;
