package Paws::CodePipeline::ArtifactStore {
  use Moose;
  has location => (is => 'ro', isa => 'Str', required => 1);
  has type => (is => 'ro', isa => 'Str', required => 1);
}
1;
