package Paws::EC2::Tag {
  use Moose;
  has Key => (is => 'ro', isa => 'Str', xmlname => 'key', traits => ['Unwrapped']);
  has Value => (is => 'ro', isa => 'Str', xmlname => 'value', traits => ['Unwrapped']);
}
1;
