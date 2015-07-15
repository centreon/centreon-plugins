package Paws::CloudSearch::DoubleArrayOptions {
  use Moose;
  has DefaultValue => (is => 'ro', isa => 'Num');
  has FacetEnabled => (is => 'ro', isa => 'Bool');
  has ReturnEnabled => (is => 'ro', isa => 'Bool');
  has SearchEnabled => (is => 'ro', isa => 'Bool');
  has SourceFields => (is => 'ro', isa => 'Str');
}
1;
