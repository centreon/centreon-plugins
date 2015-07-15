package Paws::AutoScaling::TagDescription {
  use Moose;
  has Key => (is => 'ro', isa => 'Str');
  has PropagateAtLaunch => (is => 'ro', isa => 'Bool');
  has ResourceId => (is => 'ro', isa => 'Str');
  has ResourceType => (is => 'ro', isa => 'Str');
  has Value => (is => 'ro', isa => 'Str');
}
1;
