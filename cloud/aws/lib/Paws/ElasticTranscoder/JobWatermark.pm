package Paws::ElasticTranscoder::JobWatermark {
  use Moose;
  has Encryption => (is => 'ro', isa => 'Paws::ElasticTranscoder::Encryption');
  has InputKey => (is => 'ro', isa => 'Str');
  has PresetWatermarkId => (is => 'ro', isa => 'Str');
}
1;
