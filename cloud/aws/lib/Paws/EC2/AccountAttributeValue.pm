package Paws::EC2::AccountAttributeValue {
  use Moose;
  has AttributeValue => (is => 'ro', isa => 'Str', xmlname => 'attributeValue', traits => ['Unwrapped']);
}
1;
