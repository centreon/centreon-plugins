package Paws::ElasticTranscoder::AudioParameters {
  use Moose;
  has AudioPackingMode => (is => 'ro', isa => 'Str');
  has BitRate => (is => 'ro', isa => 'Str');
  has Channels => (is => 'ro', isa => 'Str');
  has Codec => (is => 'ro', isa => 'Str');
  has CodecOptions => (is => 'ro', isa => 'Paws::ElasticTranscoder::AudioCodecOptions');
  has SampleRate => (is => 'ro', isa => 'Str');
}
1;
