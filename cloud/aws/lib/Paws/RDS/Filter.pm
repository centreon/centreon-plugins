package Paws::RDS::Filter {
  use Moose;
  has Name => (is => 'ro', isa => 'Str', required => 1);
  has Values => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
}
1;
