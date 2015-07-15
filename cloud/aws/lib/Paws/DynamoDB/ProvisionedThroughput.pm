package Paws::DynamoDB::ProvisionedThroughput {
  use Moose;
  has ReadCapacityUnits => (is => 'ro', isa => 'Int', required => 1);
  has WriteCapacityUnits => (is => 'ro', isa => 'Int', required => 1);
}
1;
