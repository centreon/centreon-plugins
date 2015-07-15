package Paws::DynamoDB::ConsumedCapacity {
  use Moose;
  has CapacityUnits => (is => 'ro', isa => 'Num');
  has GlobalSecondaryIndexes => (is => 'ro', isa => 'Paws::DynamoDB::SecondaryIndexesCapacityMap');
  has LocalSecondaryIndexes => (is => 'ro', isa => 'Paws::DynamoDB::SecondaryIndexesCapacityMap');
  has Table => (is => 'ro', isa => 'Paws::DynamoDB::Capacity');
  has TableName => (is => 'ro', isa => 'Str');
}
1;
