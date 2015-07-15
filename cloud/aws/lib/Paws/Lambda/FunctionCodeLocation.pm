package Paws::Lambda::FunctionCodeLocation {
  use Moose;
  has Location => (is => 'ro', isa => 'Str');
  has RepositoryType => (is => 'ro', isa => 'Str');
}
1;
