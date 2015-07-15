package Paws::ElasticTranscoder::VideoParameters {
  use Moose;
  has AspectRatio => (is => 'ro', isa => 'Str');
  has BitRate => (is => 'ro', isa => 'Str');
  has Codec => (is => 'ro', isa => 'Str');
  has CodecOptions => (is => 'ro', isa => 'Paws::ElasticTranscoder::CodecOptions');
  has DisplayAspectRatio => (is => 'ro', isa => 'Str');
  has FixedGOP => (is => 'ro', isa => 'Str');
  has FrameRate => (is => 'ro', isa => 'Str');
  has KeyframesMaxDist => (is => 'ro', isa => 'Str');
  has MaxFrameRate => (is => 'ro', isa => 'Str');
  has MaxHeight => (is => 'ro', isa => 'Str');
  has MaxWidth => (is => 'ro', isa => 'Str');
  has PaddingPolicy => (is => 'ro', isa => 'Str');
  has Resolution => (is => 'ro', isa => 'Str');
  has SizingPolicy => (is => 'ro', isa => 'Str');
  has Watermarks => (is => 'ro', isa => 'ArrayRef[Paws::ElasticTranscoder::PresetWatermark]');
}
1;
