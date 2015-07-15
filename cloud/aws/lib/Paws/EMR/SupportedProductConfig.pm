package Paws::EMR::SupportedProductConfig {
  use Moose;
  has Args => (is => 'ro', isa => 'ArrayRef[Str]');
  has Name => (is => 'ro', isa => 'Str');
}
1;
