package Paws::CodePipeline::OutputArtifact {
  use Moose;
  has name => (is => 'ro', isa => 'Str', required => 1);
}
1;
