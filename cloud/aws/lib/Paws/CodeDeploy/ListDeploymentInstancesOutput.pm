
package Paws::CodeDeploy::ListDeploymentInstancesOutput {
  use Moose;
  has instancesList => (is => 'ro', isa => 'ArrayRef[Str]');
  has nextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodeDeploy::ListDeploymentInstancesOutput

=head1 ATTRIBUTES

=head2 instancesList => ArrayRef[Str]

  

A list of instances IDs.









=head2 nextToken => Str

  

If the amount of information that is returned is significantly large,
an identifier will also be returned, which can be used in a subsequent
list deployment instances call to return the next set of deployment
instances in the list.











=cut

1;