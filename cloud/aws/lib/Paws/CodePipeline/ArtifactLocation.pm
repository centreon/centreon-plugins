package Paws::CodePipeline::ArtifactLocation {
  use Moose;
  has s3Location => (is => 'ro', isa => 'Paws::CodePipeline::S3ArtifactLocation');
  has type => (is => 'ro', isa => 'Str');
}
1;
