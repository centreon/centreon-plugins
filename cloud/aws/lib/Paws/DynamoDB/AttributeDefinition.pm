package Paws::DynamoDB::AttributeDefinition {
  use Moose;
  has AttributeName => (is => 'ro', isa => 'Str', required => 1);
  has AttributeType => (is => 'ro', isa => 'Str', required => 1);
}
1;
