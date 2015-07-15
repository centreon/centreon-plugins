package Paws::OpsWorks::DeploymentCommand {
  use Moose;
  has Args => (is => 'ro', isa => 'Paws::OpsWorks::DeploymentCommandArgs');
  has Name => (is => 'ro', isa => 'Str', required => 1);
}
1;
