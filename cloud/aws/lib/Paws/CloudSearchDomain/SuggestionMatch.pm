package Paws::CloudSearchDomain::SuggestionMatch {
  use Moose;
  has id => (is => 'ro', isa => 'Str');
  has score => (is => 'ro', isa => 'Int');
  has suggestion => (is => 'ro', isa => 'Str');
}
1;
