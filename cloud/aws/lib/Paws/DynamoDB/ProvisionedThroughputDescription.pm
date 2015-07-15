package Paws::DynamoDB::ProvisionedThroughputDescription {
  use Moose;
  has LastDecreaseDateTime => (is => 'ro', isa => 'Str');
  has LastIncreaseDateTime => (is => 'ro', isa => 'Str');
  has NumberOfDecreasesToday => (is => 'ro', isa => 'Int');
  has ReadCapacityUnits => (is => 'ro', isa => 'Int');
  has WriteCapacityUnits => (is => 'ro', isa => 'Int');
}
1;
