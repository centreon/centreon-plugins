
package Paws::CodeDeploy::ListDeploymentGroupsOutput {
  use Moose;
  has applicationName => (is => 'ro', isa => 'Str');
  has deploymentGroups => (is => 'ro', isa => 'ArrayRef[Str]');
  has nextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodeDeploy::ListDeploymentGroupsOutput

=head1 ATTRIBUTES

=head2 applicationName => Str

  

The application name.









=head2 deploymentGroups => ArrayRef[Str]

  

A list of corresponding deployment group names.









=head2 nextToken => Str

  

If the amount of information that is returned is significantly large,
an identifier will also be returned, which can be used in a subsequent
list deployment groups call to return the next set of deployment groups
in the list.











=cut

1;