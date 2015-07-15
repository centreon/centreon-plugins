package Paws::DynamoDB::GlobalSecondaryIndexDescription {
  use Moose;
  has Backfilling => (is => 'ro', isa => 'Bool');
  has IndexName => (is => 'ro', isa => 'Str');
  has IndexSizeBytes => (is => 'ro', isa => 'Int');
  has IndexStatus => (is => 'ro', isa => 'Str');
  has ItemCount => (is => 'ro', isa => 'Int');
  has KeySchema => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDB::KeySchemaElement]');
  has Projection => (is => 'ro', isa => 'Paws::DynamoDB::Projection');
  has ProvisionedThroughput => (is => 'ro', isa => 'Paws::DynamoDB::ProvisionedThroughputDescription');
}
1;
