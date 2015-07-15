package Paws::EC2::PriceScheduleSpecification {
  use Moose;
  has CurrencyCode => (is => 'ro', isa => 'Str', xmlname => 'currencyCode', traits => ['Unwrapped']);
  has Price => (is => 'ro', isa => 'Num', xmlname => 'price', traits => ['Unwrapped']);
  has Term => (is => 'ro', isa => 'Int', xmlname => 'term', traits => ['Unwrapped']);
}
1;
