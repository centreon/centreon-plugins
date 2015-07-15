package Paws::ElasticTranscoder::Pipeline {
  use Moose;
  has Arn => (is => 'ro', isa => 'Str');
  has AwsKmsKeyArn => (is => 'ro', isa => 'Str');
  has ContentConfig => (is => 'ro', isa => 'Paws::ElasticTranscoder::PipelineOutputConfig');
  has Id => (is => 'ro', isa => 'Str');
  has InputBucket => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
  has Notifications => (is => 'ro', isa => 'Paws::ElasticTranscoder::Notifications');
  has OutputBucket => (is => 'ro', isa => 'Str');
  has Role => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Str');
  has ThumbnailConfig => (is => 'ro', isa => 'Paws::ElasticTranscoder::PipelineOutputConfig');
}
1;
