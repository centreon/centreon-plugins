package Paws::CodeDeploy::DeploymentInfo {
  use Moose;
  has applicationName => (is => 'ro', isa => 'Str');
  has completeTime => (is => 'ro', isa => 'Str');
  has createTime => (is => 'ro', isa => 'Str');
  has creator => (is => 'ro', isa => 'Str');
  has deploymentConfigName => (is => 'ro', isa => 'Str');
  has deploymentGroupName => (is => 'ro', isa => 'Str');
  has deploymentId => (is => 'ro', isa => 'Str');
  has deploymentOverview => (is => 'ro', isa => 'Paws::CodeDeploy::DeploymentOverview');
  has description => (is => 'ro', isa => 'Str');
  has errorInformation => (is => 'ro', isa => 'Paws::CodeDeploy::ErrorInformation');
  has ignoreApplicationStopFailures => (is => 'ro', isa => 'Bool');
  has revision => (is => 'ro', isa => 'Paws::CodeDeploy::RevisionLocation');
  has startTime => (is => 'ro', isa => 'Str');
  has status => (is => 'ro', isa => 'Str');
}
1;
