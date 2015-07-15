package Paws::CodeDeploy::DeploymentGroupInfo {
  use Moose;
  has applicationName => (is => 'ro', isa => 'Str');
  has autoScalingGroups => (is => 'ro', isa => 'ArrayRef[Paws::CodeDeploy::AutoScalingGroup]');
  has deploymentConfigName => (is => 'ro', isa => 'Str');
  has deploymentGroupId => (is => 'ro', isa => 'Str');
  has deploymentGroupName => (is => 'ro', isa => 'Str');
  has ec2TagFilters => (is => 'ro', isa => 'ArrayRef[Paws::CodeDeploy::EC2TagFilter]');
  has onPremisesInstanceTagFilters => (is => 'ro', isa => 'ArrayRef[Paws::CodeDeploy::TagFilter]');
  has serviceRoleArn => (is => 'ro', isa => 'Str');
  has targetRevision => (is => 'ro', isa => 'Paws::CodeDeploy::RevisionLocation');
}
1;
