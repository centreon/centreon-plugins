package Paws::ElasticTranscoder::Thumbnails {
  use Moose;
  has AspectRatio => (is => 'ro', isa => 'Str');
  has Format => (is => 'ro', isa => 'Str');
  has Interval => (is => 'ro', isa => 'Str');
  has MaxHeight => (is => 'ro', isa => 'Str');
  has MaxWidth => (is => 'ro', isa => 'Str');
  has PaddingPolicy => (is => 'ro', isa => 'Str');
  has Resolution => (is => 'ro', isa => 'Str');
  has SizingPolicy => (is => 'ro', isa => 'Str');
}
1;
