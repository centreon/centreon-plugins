package Paws::ELB::AdditionalAttribute {
  use Moose;
  has Key => (is => 'ro', isa => 'Str');
  has Value => (is => 'ro', isa => 'Str');
}
1;
