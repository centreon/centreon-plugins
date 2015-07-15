package Paws::ElasticTranscoder::Captions {
  use Moose;
  has CaptionFormats => (is => 'ro', isa => 'ArrayRef[Paws::ElasticTranscoder::CaptionFormat]');
  has CaptionSources => (is => 'ro', isa => 'ArrayRef[Paws::ElasticTranscoder::CaptionSource]');
  has MergePolicy => (is => 'ro', isa => 'Str');
}
1;
