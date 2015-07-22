package Paws::CodePipeline::ActionDeclaration {
  use Moose;
  has actionTypeId => (is => 'ro', isa => 'Paws::CodePipeline::ActionTypeId', required => 1);
  has configuration => (is => 'ro', isa => 'Paws::CodePipeline::ActionConfigurationMap');
  has inputArtifacts => (is => 'ro', isa => 'ArrayRef[Paws::CodePipeline::InputArtifact]');
  has name => (is => 'ro', isa => 'Str', required => 1);
  has outputArtifacts => (is => 'ro', isa => 'ArrayRef[Paws::CodePipeline::OutputArtifact]');
  has roleArn => (is => 'ro', isa => 'Str');
  has runOrder => (is => 'ro', isa => 'Int');
}
1;
