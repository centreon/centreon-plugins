package Paws::CodePipeline::S3ArtifactLocation {
  use Moose;
  has bucketName => (is => 'ro', isa => 'Str', required => 1);
  has objectKey => (is => 'ro', isa => 'Str', required => 1);
}
1;
