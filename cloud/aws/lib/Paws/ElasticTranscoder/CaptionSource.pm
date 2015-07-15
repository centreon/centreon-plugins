package Paws::ElasticTranscoder::CaptionSource {
  use Moose;
  has Encryption => (is => 'ro', isa => 'Paws::ElasticTranscoder::Encryption');
  has Key => (is => 'ro', isa => 'Str');
  has Label => (is => 'ro', isa => 'Str');
  has Language => (is => 'ro', isa => 'Str');
  has TimeOffset => (is => 'ro', isa => 'Str');
}
1;
