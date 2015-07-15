package Paws::CloudSearch::TextOptions {
  use Moose;
  has AnalysisScheme => (is => 'ro', isa => 'Str');
  has DefaultValue => (is => 'ro', isa => 'Str');
  has HighlightEnabled => (is => 'ro', isa => 'Bool');
  has ReturnEnabled => (is => 'ro', isa => 'Bool');
  has SortEnabled => (is => 'ro', isa => 'Bool');
  has SourceField => (is => 'ro', isa => 'Str');
}
1;
