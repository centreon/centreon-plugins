package Paws::CloudSearch::IndexFieldStatus {
  use Moose;
  has Options => (is => 'ro', isa => 'Paws::CloudSearch::IndexField', required => 1);
  has Status => (is => 'ro', isa => 'Paws::CloudSearch::OptionStatus', required => 1);
}
1;
