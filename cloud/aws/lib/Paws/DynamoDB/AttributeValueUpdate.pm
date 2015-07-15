package Paws::DynamoDB::AttributeValueUpdate {
  use Moose;
  has Action => (is => 'ro', isa => 'Str');
  has Value => (is => 'ro', isa => 'Paws::DynamoDB::AttributeValue');
}
1;
