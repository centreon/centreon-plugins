
package Paws::CodeDeploy::ListOnPremisesInstancesOutput {
  use Moose;
  has instanceNames => (is => 'ro', isa => 'ArrayRef[Str]');
  has nextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodeDeploy::ListOnPremisesInstancesOutput

=head1 ATTRIBUTES

=head2 instanceNames => ArrayRef[Str]

  

The list of matching on-premises instance names.









=head2 nextToken => Str

  

If the amount of information that is returned is significantly large,
an identifier will also be returned, which can be used in a subsequent
list on-premises instances call to return the next set of on-premises
instances in the list.











=cut

1;