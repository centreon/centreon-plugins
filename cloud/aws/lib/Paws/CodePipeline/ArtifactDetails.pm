package Paws::CodePipeline::ArtifactDetails {
  use Moose;
  has maximumCount => (is => 'ro', isa => 'Int', required => 1);
  has minimumCount => (is => 'ro', isa => 'Int', required => 1);
}
1;
