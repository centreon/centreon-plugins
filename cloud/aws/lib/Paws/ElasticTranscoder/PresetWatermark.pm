package Paws::ElasticTranscoder::PresetWatermark {
  use Moose;
  has HorizontalAlign => (is => 'ro', isa => 'Str');
  has HorizontalOffset => (is => 'ro', isa => 'Str');
  has Id => (is => 'ro', isa => 'Str');
  has MaxHeight => (is => 'ro', isa => 'Str');
  has MaxWidth => (is => 'ro', isa => 'Str');
  has Opacity => (is => 'ro', isa => 'Str');
  has SizingPolicy => (is => 'ro', isa => 'Str');
  has Target => (is => 'ro', isa => 'Str');
  has VerticalAlign => (is => 'ro', isa => 'Str');
  has VerticalOffset => (is => 'ro', isa => 'Str');
}
1;
