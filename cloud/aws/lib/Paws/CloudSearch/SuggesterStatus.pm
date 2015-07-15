package Paws::CloudSearch::SuggesterStatus {
  use Moose;
  has Options => (is => 'ro', isa => 'Paws::CloudSearch::Suggester', required => 1);
  has Status => (is => 'ro', isa => 'Paws::CloudSearch::OptionStatus', required => 1);
}
1;
