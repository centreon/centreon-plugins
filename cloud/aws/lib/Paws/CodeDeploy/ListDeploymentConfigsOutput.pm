
package Paws::CodeDeploy::ListDeploymentConfigsOutput {
  use Moose;
  has deploymentConfigsList => (is => 'ro', isa => 'ArrayRef[Str]');
  has nextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodeDeploy::ListDeploymentConfigsOutput

=head1 ATTRIBUTES

=head2 deploymentConfigsList => ArrayRef[Str]

  

A list of deployment configurations, including the built-in
configurations such as CodeDeployDefault.OneAtATime.









=head2 nextToken => Str

  

If the amount of information that is returned is significantly large,
an identifier will also be returned, which can be used in a subsequent
list deployment configurations call to return the next set of
deployment configurations in the list.











=cut

1;