package Paws::EC2::Filter {
  use Moose;
  has Name => (is => 'ro', isa => 'Str');
  has Values => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'Value', traits => ['Unwrapped']);
}
1;
