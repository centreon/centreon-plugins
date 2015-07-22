package Paws::DeviceFarm::UniqueProblem {
  use Moose;
  has message => (is => 'ro', isa => 'Str');
  has problems => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::Problem]');
}
1;
