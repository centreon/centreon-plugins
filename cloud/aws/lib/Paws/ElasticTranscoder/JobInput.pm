package Paws::ElasticTranscoder::JobInput {
  use Moose;
  has AspectRatio => (is => 'ro', isa => 'Str');
  has Container => (is => 'ro', isa => 'Str');
  has DetectedProperties => (is => 'ro', isa => 'Paws::ElasticTranscoder::DetectedProperties');
  has Encryption => (is => 'ro', isa => 'Paws::ElasticTranscoder::Encryption');
  has FrameRate => (is => 'ro', isa => 'Str');
  has Interlaced => (is => 'ro', isa => 'Str');
  has Key => (is => 'ro', isa => 'Str');
  has Resolution => (is => 'ro', isa => 'Str');
}
1;
