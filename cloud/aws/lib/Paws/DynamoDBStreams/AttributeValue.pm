package Paws::DynamoDBStreams::AttributeValue {
  use Moose;
  has B => (is => 'ro', isa => 'Str');
  has BOOL => (is => 'ro', isa => 'Bool');
  has BS => (is => 'ro', isa => 'ArrayRef[Str]');
  has L => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDBStreams::AttributeValue]');
  has M => (is => 'ro', isa => 'Paws::DynamoDBStreams::MapAttributeValue');
  has N => (is => 'ro', isa => 'Str');
  has NS => (is => 'ro', isa => 'ArrayRef[Str]');
  has NULL => (is => 'ro', isa => 'Bool');
  has S => (is => 'ro', isa => 'Str');
  has SS => (is => 'ro', isa => 'ArrayRef[Str]');
}
1;
