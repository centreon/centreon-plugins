package Paws::ELB::PolicyAttributeDescription {
  use Moose;
  has AttributeName => (is => 'ro', isa => 'Str');
  has AttributeValue => (is => 'ro', isa => 'Str');
}
1;
