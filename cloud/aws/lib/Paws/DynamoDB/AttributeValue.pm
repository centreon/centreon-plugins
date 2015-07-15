package Paws::DynamoDB::AttributeValue {
  use Moose;
  has B => (is => 'ro', isa => 'Str');
  has BOOL => (is => 'ro', isa => 'Bool');
  has BS => (is => 'ro', isa => 'ArrayRef[Str]');
  has L => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDB::AttributeValue]');
  has M => (is => 'ro', isa => 'Paws::DynamoDB::MapAttributeValue');
  has N => (is => 'ro', isa => 'Str');
  has NS => (is => 'ro', isa => 'ArrayRef[Str]');
  has NULL => (is => 'ro', isa => 'Bool');
  has S => (is => 'ro', isa => 'Str');
  has SS => (is => 'ro', isa => 'ArrayRef[Str]');
}
1;
