package Paws::DS::Computer {
  use Moose;
  has ComputerAttributes => (is => 'ro', isa => 'ArrayRef[Paws::DS::Attribute]');
  has ComputerId => (is => 'ro', isa => 'Str');
  has ComputerName => (is => 'ro', isa => 'Str');
}
1;
