package Paws::CodePipeline::InputArtifact {
  use Moose;
  has name => (is => 'ro', isa => 'Str', required => 1);
}
1;
