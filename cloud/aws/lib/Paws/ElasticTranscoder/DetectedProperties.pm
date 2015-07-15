package Paws::ElasticTranscoder::DetectedProperties {
  use Moose;
  has DurationMillis => (is => 'ro', isa => 'Int');
  has FileSize => (is => 'ro', isa => 'Int');
  has FrameRate => (is => 'ro', isa => 'Str');
  has Height => (is => 'ro', isa => 'Int');
  has Width => (is => 'ro', isa => 'Int');
}
1;
