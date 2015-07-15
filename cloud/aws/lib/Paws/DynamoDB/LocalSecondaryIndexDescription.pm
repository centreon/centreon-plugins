package Paws::DynamoDB::LocalSecondaryIndexDescription {
  use Moose;
  has IndexName => (is => 'ro', isa => 'Str');
  has IndexSizeBytes => (is => 'ro', isa => 'Int');
  has ItemCount => (is => 'ro', isa => 'Int');
  has KeySchema => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDB::KeySchemaElement]');
  has Projection => (is => 'ro', isa => 'Paws::DynamoDB::Projection');
}
1;
