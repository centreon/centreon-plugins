package Paws::ElasticTranscoder::AudioCodecOptions {
  use Moose;
  has BitDepth => (is => 'ro', isa => 'Str');
  has BitOrder => (is => 'ro', isa => 'Str');
  has Profile => (is => 'ro', isa => 'Str');
  has Signed => (is => 'ro', isa => 'Str');
}
1;
