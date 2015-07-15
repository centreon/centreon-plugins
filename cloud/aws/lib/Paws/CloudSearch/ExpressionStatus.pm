package Paws::CloudSearch::ExpressionStatus {
  use Moose;
  has Options => (is => 'ro', isa => 'Paws::CloudSearch::Expression', required => 1);
  has Status => (is => 'ro', isa => 'Paws::CloudSearch::OptionStatus', required => 1);
}
1;
