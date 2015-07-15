package Paws::CodeDeploy::TagFilter {
  use Moose;
  has Key => (is => 'ro', isa => 'Str');
  has Type => (is => 'ro', isa => 'Str');
  has Value => (is => 'ro', isa => 'Str');
}
1;
