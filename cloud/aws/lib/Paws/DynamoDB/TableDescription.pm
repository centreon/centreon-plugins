package Paws::DynamoDB::TableDescription {
  use Moose;
  has AttributeDefinitions => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDB::AttributeDefinition]');
  has CreationDateTime => (is => 'ro', isa => 'Str');
  has GlobalSecondaryIndexes => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDB::GlobalSecondaryIndexDescription]');
  has ItemCount => (is => 'ro', isa => 'Int');
  has KeySchema => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDB::KeySchemaElement]');
  has LatestStreamArn => (is => 'ro', isa => 'Str');
  has LatestStreamLabel => (is => 'ro', isa => 'Str');
  has LocalSecondaryIndexes => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDB::LocalSecondaryIndexDescription]');
  has ProvisionedThroughput => (is => 'ro', isa => 'Paws::DynamoDB::ProvisionedThroughputDescription');
  has StreamSpecification => (is => 'ro', isa => 'Paws::DynamoDB::StreamSpecification');
  has TableArn => (is => 'ro', isa => 'Str');
  has TableName => (is => 'ro', isa => 'Str');
  has TableSizeBytes => (is => 'ro', isa => 'Int');
  has TableStatus => (is => 'ro', isa => 'Str');
}
1;
