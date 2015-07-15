package Paws::CloudSearch::DocumentSuggesterOptions {
  use Moose;
  has FuzzyMatching => (is => 'ro', isa => 'Str');
  has SortExpression => (is => 'ro', isa => 'Str');
  has SourceField => (is => 'ro', isa => 'Str', required => 1);
}
1;
