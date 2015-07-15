package Paws::ElasticTranscoder::CaptionFormat {
  use Moose;
  has Encryption => (is => 'ro', isa => 'Paws::ElasticTranscoder::Encryption');
  has Format => (is => 'ro', isa => 'Str');
  has Pattern => (is => 'ro', isa => 'Str');
}
1;
