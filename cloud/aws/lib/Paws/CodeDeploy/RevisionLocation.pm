package Paws::CodeDeploy::RevisionLocation {
  use Moose;
  has gitHubLocation => (is => 'ro', isa => 'Paws::CodeDeploy::GitHubLocation');
  has revisionType => (is => 'ro', isa => 'Str');
  has s3Location => (is => 'ro', isa => 'Paws::CodeDeploy::S3Location');
}
1;
