package Paws::CloudSearch::Expression {
  use Moose;
  has ExpressionName => (is => 'ro', isa => 'Str', required => 1);
  has ExpressionValue => (is => 'ro', isa => 'Str', required => 1);
}
1;
