package Paws::EC2::TagDescription {
  use Moose;
  has Key => (is => 'ro', isa => 'Str', xmlname => 'key', traits => ['Unwrapped']);
  has ResourceId => (is => 'ro', isa => 'Str', xmlname => 'resourceId', traits => ['Unwrapped']);
  has ResourceType => (is => 'ro', isa => 'Str', xmlname => 'resourceType', traits => ['Unwrapped']);
  has Value => (is => 'ro', isa => 'Str', xmlname => 'value', traits => ['Unwrapped']);
}
1;
