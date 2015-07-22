package Paws::CodePipeline::Artifact {
  use Moose;
  has location => (is => 'ro', isa => 'Paws::CodePipeline::ArtifactLocation');
  has name => (is => 'ro', isa => 'Str');
  has revision => (is => 'ro', isa => 'Str');
}
1;
