package Paws::CodePipeline::JobData {
  use Moose;
  has actionConfiguration => (is => 'ro', isa => 'Paws::CodePipeline::ActionConfiguration');
  has actionTypeId => (is => 'ro', isa => 'Paws::CodePipeline::ActionTypeId');
  has artifactCredentials => (is => 'ro', isa => 'Paws::CodePipeline::AWSSessionCredentials');
  has continuationToken => (is => 'ro', isa => 'Str');
  has inputArtifacts => (is => 'ro', isa => 'ArrayRef[Paws::CodePipeline::Artifact]');
  has outputArtifacts => (is => 'ro', isa => 'ArrayRef[Paws::CodePipeline::Artifact]');
  has pipelineContext => (is => 'ro', isa => 'Paws::CodePipeline::PipelineContext');
}
1;
