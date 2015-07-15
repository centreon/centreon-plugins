package Paws::DynamoDB::Capacity {
  use Moose;
  has CapacityUnits => (is => 'ro', isa => 'Num');
}
1;
