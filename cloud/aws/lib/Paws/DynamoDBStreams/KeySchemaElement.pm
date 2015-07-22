package Paws::DynamoDBStreams::KeySchemaElement {
  use Moose;
  has AttributeName => (is => 'ro', isa => 'Str', required => 1);
  has KeyType => (is => 'ro', isa => 'Str', required => 1);
}
1;
