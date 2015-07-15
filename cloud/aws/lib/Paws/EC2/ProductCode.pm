package Paws::EC2::ProductCode {
  use Moose;
  has ProductCodeId => (is => 'ro', isa => 'Str', xmlname => 'productCode', traits => ['Unwrapped']);
  has ProductCodeType => (is => 'ro', isa => 'Str', xmlname => 'type', traits => ['Unwrapped']);
}
1;
