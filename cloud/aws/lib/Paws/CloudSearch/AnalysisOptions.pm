package Paws::CloudSearch::AnalysisOptions {
  use Moose;
  has AlgorithmicStemming => (is => 'ro', isa => 'Str');
  has JapaneseTokenizationDictionary => (is => 'ro', isa => 'Str');
  has StemmingDictionary => (is => 'ro', isa => 'Str');
  has Stopwords => (is => 'ro', isa => 'Str');
  has Synonyms => (is => 'ro', isa => 'Str');
}
1;
