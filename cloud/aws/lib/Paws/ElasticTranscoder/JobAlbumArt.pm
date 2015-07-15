package Paws::ElasticTranscoder::JobAlbumArt {
  use Moose;
  has Artwork => (is => 'ro', isa => 'ArrayRef[Paws::ElasticTranscoder::Artwork]');
  has MergePolicy => (is => 'ro', isa => 'Str');
}
1;
