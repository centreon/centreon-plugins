package Paws::CodeDeploy::DeploymentOverview {
  use Moose;
  has Failed => (is => 'ro', isa => 'Int');
  has InProgress => (is => 'ro', isa => 'Int');
  has Pending => (is => 'ro', isa => 'Int');
  has Skipped => (is => 'ro', isa => 'Int');
  has Succeeded => (is => 'ro', isa => 'Int');
}
1;
