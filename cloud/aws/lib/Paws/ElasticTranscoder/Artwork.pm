package Paws::ElasticTranscoder::Artwork {
  use Moose;
  has AlbumArtFormat => (is => 'ro', isa => 'Str');
  has Encryption => (is => 'ro', isa => 'Paws::ElasticTranscoder::Encryption');
  has InputKey => (is => 'ro', isa => 'Str');
  has MaxHeight => (is => 'ro', isa => 'Str');
  has MaxWidth => (is => 'ro', isa => 'Str');
  has PaddingPolicy => (is => 'ro', isa => 'Str');
  has SizingPolicy => (is => 'ro', isa => 'Str');
}
1;
