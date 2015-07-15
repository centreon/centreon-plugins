package Paws::EC2::AccountAttribute {
  use Moose;
  has AttributeName => (is => 'ro', isa => 'Str', xmlname => 'attributeName', traits => ['Unwrapped']);
  has AttributeValues => (is => 'ro', isa => 'ArrayRef[Paws::EC2::AccountAttributeValue]', xmlname => 'attributeValueSet', traits => ['Unwrapped']);
}
1;
