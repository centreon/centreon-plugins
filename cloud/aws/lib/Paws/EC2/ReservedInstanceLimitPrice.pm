package Paws::EC2::ReservedInstanceLimitPrice {
  use Moose;
  has Amount => (is => 'ro', isa => 'Num', xmlname => 'amount', traits => ['Unwrapped']);
  has CurrencyCode => (is => 'ro', isa => 'Str', xmlname => 'currencyCode', traits => ['Unwrapped']);
}
1;
