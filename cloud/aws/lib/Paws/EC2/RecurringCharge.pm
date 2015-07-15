package Paws::EC2::RecurringCharge {
  use Moose;
  has Amount => (is => 'ro', isa => 'Num', xmlname => 'amount', traits => ['Unwrapped']);
  has Frequency => (is => 'ro', isa => 'Str', xmlname => 'frequency', traits => ['Unwrapped']);
}
1;
