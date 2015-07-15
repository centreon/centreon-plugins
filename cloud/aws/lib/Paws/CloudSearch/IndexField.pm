package Paws::CloudSearch::IndexField {
  use Moose;
  has DateArrayOptions => (is => 'ro', isa => 'Paws::CloudSearch::DateArrayOptions');
  has DateOptions => (is => 'ro', isa => 'Paws::CloudSearch::DateOptions');
  has DoubleArrayOptions => (is => 'ro', isa => 'Paws::CloudSearch::DoubleArrayOptions');
  has DoubleOptions => (is => 'ro', isa => 'Paws::CloudSearch::DoubleOptions');
  has IndexFieldName => (is => 'ro', isa => 'Str', required => 1);
  has IndexFieldType => (is => 'ro', isa => 'Str', required => 1);
  has IntArrayOptions => (is => 'ro', isa => 'Paws::CloudSearch::IntArrayOptions');
  has IntOptions => (is => 'ro', isa => 'Paws::CloudSearch::IntOptions');
  has LatLonOptions => (is => 'ro', isa => 'Paws::CloudSearch::LatLonOptions');
  has LiteralArrayOptions => (is => 'ro', isa => 'Paws::CloudSearch::LiteralArrayOptions');
  has LiteralOptions => (is => 'ro', isa => 'Paws::CloudSearch::LiteralOptions');
  has TextArrayOptions => (is => 'ro', isa => 'Paws::CloudSearch::TextArrayOptions');
  has TextOptions => (is => 'ro', isa => 'Paws::CloudSearch::TextOptions');
}
1;
