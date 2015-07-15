package Paws::ElasticTranscoder::Job {
  use Moose;
  has Arn => (is => 'ro', isa => 'Str');
  has Id => (is => 'ro', isa => 'Str');
  has Input => (is => 'ro', isa => 'Paws::ElasticTranscoder::JobInput');
  has Output => (is => 'ro', isa => 'Paws::ElasticTranscoder::JobOutput');
  has OutputKeyPrefix => (is => 'ro', isa => 'Str');
  has Outputs => (is => 'ro', isa => 'ArrayRef[Paws::ElasticTranscoder::JobOutput]');
  has PipelineId => (is => 'ro', isa => 'Str');
  has Playlists => (is => 'ro', isa => 'ArrayRef[Paws::ElasticTranscoder::Playlist]');
  has Status => (is => 'ro', isa => 'Str');
  has Timing => (is => 'ro', isa => 'Paws::ElasticTranscoder::Timing');
  has UserMetadata => (is => 'ro', isa => 'Paws::ElasticTranscoder::UserMetadata');
}
1;
