package Paws::EC2::PricingDetail {
  use Moose;
  has Count => (is => 'ro', isa => 'Int', xmlname => 'count', traits => ['Unwrapped']);
  has Price => (is => 'ro', isa => 'Num', xmlname => 'price', traits => ['Unwrapped']);
}
1;
