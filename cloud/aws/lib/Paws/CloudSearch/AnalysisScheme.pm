package Paws::CloudSearch::AnalysisScheme {
  use Moose;
  has AnalysisOptions => (is => 'ro', isa => 'Paws::CloudSearch::AnalysisOptions');
  has AnalysisSchemeLanguage => (is => 'ro', isa => 'Str', required => 1);
  has AnalysisSchemeName => (is => 'ro', isa => 'Str', required => 1);
}
1;
