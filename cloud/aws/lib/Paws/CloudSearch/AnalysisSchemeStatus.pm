package Paws::CloudSearch::AnalysisSchemeStatus {
  use Moose;
  has Options => (is => 'ro', isa => 'Paws::CloudSearch::AnalysisScheme', required => 1);
  has Status => (is => 'ro', isa => 'Paws::CloudSearch::OptionStatus', required => 1);
}
1;
