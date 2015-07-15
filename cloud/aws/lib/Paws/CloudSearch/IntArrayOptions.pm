package Paws::CloudSearch::IntArrayOptions {
  use Moose;
  has DefaultValue => (is => 'ro', isa => 'Int');
  has FacetEnabled => (is => 'ro', isa => 'Bool');
  has ReturnEnabled => (is => 'ro', isa => 'Bool');
  has SearchEnabled => (is => 'ro', isa => 'Bool');
  has SourceFields => (is => 'ro', isa => 'Str');
}
1;
