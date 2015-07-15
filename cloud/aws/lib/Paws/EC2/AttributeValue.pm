package Paws::EC2::AttributeValue {
  use Moose;
  has Value => (is => 'ro', isa => 'Str', xmlname => 'value', traits => ['Unwrapped']);
}
1;
