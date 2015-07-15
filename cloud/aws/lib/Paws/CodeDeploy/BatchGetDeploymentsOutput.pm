
package Paws::CodeDeploy::BatchGetDeploymentsOutput {
  use Moose;
  has deploymentsInfo => (is => 'ro', isa => 'ArrayRef[Paws::CodeDeploy::DeploymentInfo]');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodeDeploy::BatchGetDeploymentsOutput

=head1 ATTRIBUTES

=head2 deploymentsInfo => ArrayRef[Paws::CodeDeploy::DeploymentInfo]

  

Information about the deployments.











=cut

1;