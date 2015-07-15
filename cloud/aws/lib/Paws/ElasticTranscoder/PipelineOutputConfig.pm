package Paws::ElasticTranscoder::PipelineOutputConfig {
  use Moose;
  has Bucket => (is => 'ro', isa => 'Str');
  has Permissions => (is => 'ro', isa => 'ArrayRef[Paws::ElasticTranscoder::Permission]');
  has StorageClass => (is => 'ro', isa => 'Str');
}
1;
