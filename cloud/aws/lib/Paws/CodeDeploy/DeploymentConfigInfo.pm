package Paws::CodeDeploy::DeploymentConfigInfo {
  use Moose;
  has createTime => (is => 'ro', isa => 'Str');
  has deploymentConfigId => (is => 'ro', isa => 'Str');
  has deploymentConfigName => (is => 'ro', isa => 'Str');
  has minimumHealthyHosts => (is => 'ro', isa => 'Paws::CodeDeploy::MinimumHealthyHosts');
}
1;
