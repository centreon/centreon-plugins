package Paws::DynamoDB::ExpectedAttributeValue {
  use Moose;
  has AttributeValueList => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDB::AttributeValue]');
  has ComparisonOperator => (is => 'ro', isa => 'Str');
  has Exists => (is => 'ro', isa => 'Bool');
  has Value => (is => 'ro', isa => 'Paws::DynamoDB::AttributeValue');
}
1;
