package Paws::CodePipeline::PipelineDeclaration {
  use Moose;
  has artifactStore => (is => 'ro', isa => 'Paws::CodePipeline::ArtifactStore', required => 1);
  has name => (is => 'ro', isa => 'Str', required => 1);
  has roleArn => (is => 'ro', isa => 'Str', required => 1);
  has stages => (is => 'ro', isa => 'ArrayRef[Paws::CodePipeline::StageDeclaration]', required => 1);
  has version => (is => 'ro', isa => 'Int');
}
1;
