package Paws::EC2::PriceSchedule {
  use Moose;
  has Active => (is => 'ro', isa => 'Bool', xmlname => 'active', traits => ['Unwrapped']);
  has CurrencyCode => (is => 'ro', isa => 'Str', xmlname => 'currencyCode', traits => ['Unwrapped']);
  has Price => (is => 'ro', isa => 'Num', xmlname => 'price', traits => ['Unwrapped']);
  has Term => (is => 'ro', isa => 'Int', xmlname => 'term', traits => ['Unwrapped']);
}
1;
