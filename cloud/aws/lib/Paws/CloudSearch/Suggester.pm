package Paws::CloudSearch::Suggester {
  use Moose;
  has DocumentSuggesterOptions => (is => 'ro', isa => 'Paws::CloudSearch::DocumentSuggesterOptions', required => 1);
  has SuggesterName => (is => 'ro', isa => 'Str', required => 1);
}
1;
