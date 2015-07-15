package Paws::ElasticTranscoder::JobOutput {
  use Moose;
  has AlbumArt => (is => 'ro', isa => 'Paws::ElasticTranscoder::JobAlbumArt');
  has AppliedColorSpaceConversion => (is => 'ro', isa => 'Str');
  has Captions => (is => 'ro', isa => 'Paws::ElasticTranscoder::Captions');
  has Composition => (is => 'ro', isa => 'ArrayRef[Paws::ElasticTranscoder::Clip]');
  has Duration => (is => 'ro', isa => 'Int');
  has DurationMillis => (is => 'ro', isa => 'Int');
  has Encryption => (is => 'ro', isa => 'Paws::ElasticTranscoder::Encryption');
  has FileSize => (is => 'ro', isa => 'Int');
  has FrameRate => (is => 'ro', isa => 'Str');
  has Height => (is => 'ro', isa => 'Int');
  has Id => (is => 'ro', isa => 'Str');
  has Key => (is => 'ro', isa => 'Str');
  has PresetId => (is => 'ro', isa => 'Str');
  has Rotate => (is => 'ro', isa => 'Str');
  has SegmentDuration => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Str');
  has StatusDetail => (is => 'ro', isa => 'Str');
  has ThumbnailEncryption => (is => 'ro', isa => 'Paws::ElasticTranscoder::Encryption');
  has ThumbnailPattern => (is => 'ro', isa => 'Str');
  has Watermarks => (is => 'ro', isa => 'ArrayRef[Paws::ElasticTranscoder::JobWatermark]');
  has Width => (is => 'ro', isa => 'Int');
}
1;
