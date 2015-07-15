package Paws::ElasticTranscoder::Preset {
  use Moose;
  has Arn => (is => 'ro', isa => 'Str');
  has Audio => (is => 'ro', isa => 'Paws::ElasticTranscoder::AudioParameters');
  has Container => (is => 'ro', isa => 'Str');
  has Description => (is => 'ro', isa => 'Str');
  has Id => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
  has Thumbnails => (is => 'ro', isa => 'Paws::ElasticTranscoder::Thumbnails');
  has Type => (is => 'ro', isa => 'Str');
  has Video => (is => 'ro', isa => 'Paws::ElasticTranscoder::VideoParameters');
}
1;
