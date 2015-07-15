
package Paws::CodeDeploy::ListDeploymentsOutput {
  use Moose;
  has deployments => (is => 'ro', isa => 'ArrayRef[Str]');
  has nextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodeDeploy::ListDeploymentsOutput

=head1 ATTRIBUTES

=head2 deployments => ArrayRef[Str]

  

A list of deployment IDs.









=head2 nextToken => Str

  

If the amount of information that is returned is significantly large,
an identifier will also be returned, which can be used in a subsequent
list deployments call to return the next set of deployments in the
list.











=cut

1;