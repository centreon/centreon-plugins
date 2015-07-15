package Paws::DynamoDB::Condition {
  use Moose;
  has AttributeValueList => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDB::AttributeValue]');
  has ComparisonOperator => (is => 'ro', isa => 'Str', required => 1);
}
1;
