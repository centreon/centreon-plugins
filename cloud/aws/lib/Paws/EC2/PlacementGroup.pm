package Paws::EC2::PlacementGroup {
  use Moose;
  has GroupName => (is => 'ro', isa => 'Str', xmlname => 'groupName', traits => ['Unwrapped']);
  has State => (is => 'ro', isa => 'Str', xmlname => 'state', traits => ['Unwrapped']);
  has Strategy => (is => 'ro', isa => 'Str', xmlname => 'strategy', traits => ['Unwrapped']);
}
1;
