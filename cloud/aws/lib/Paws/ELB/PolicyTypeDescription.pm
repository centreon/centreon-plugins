package Paws::ELB::PolicyTypeDescription {
  use Moose;
  has Description => (is => 'ro', isa => 'Str');
  has PolicyAttributeTypeDescriptions => (is => 'ro', isa => 'ArrayRef[Paws::ELB::PolicyAttributeTypeDescription]');
  has PolicyTypeName => (is => 'ro', isa => 'Str');
}
1;
