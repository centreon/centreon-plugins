package Paws::ELB::PolicyDescription {
  use Moose;
  has PolicyAttributeDescriptions => (is => 'ro', isa => 'ArrayRef[Paws::ELB::PolicyAttributeDescription]');
  has PolicyName => (is => 'ro', isa => 'Str');
  has PolicyTypeName => (is => 'ro', isa => 'Str');
}
1;
