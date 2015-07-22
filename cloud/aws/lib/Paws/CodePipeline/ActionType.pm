package Paws::CodePipeline::ActionType {
  use Moose;
  has actionConfigurationProperties => (is => 'ro', isa => 'ArrayRef[Paws::CodePipeline::ActionConfigurationProperty]');
  has id => (is => 'ro', isa => 'Paws::CodePipeline::ActionTypeId', required => 1);
  has inputArtifactDetails => (is => 'ro', isa => 'Paws::CodePipeline::ArtifactDetails', required => 1);
  has outputArtifactDetails => (is => 'ro', isa => 'Paws::CodePipeline::ArtifactDetails', required => 1);
  has settings => (is => 'ro', isa => 'Paws::CodePipeline::ActionTypeSettings');
}
1;
