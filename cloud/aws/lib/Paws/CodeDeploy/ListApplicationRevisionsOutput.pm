
package Paws::CodeDeploy::ListApplicationRevisionsOutput {
  use Moose;
  has nextToken => (is => 'ro', isa => 'Str');
  has revisions => (is => 'ro', isa => 'ArrayRef[Paws::CodeDeploy::RevisionLocation]');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodeDeploy::ListApplicationRevisionsOutput

=head1 ATTRIBUTES

=head2 nextToken => Str

  

If the amount of information that is returned is significantly large,
an identifier will also be returned, which can be used in a subsequent
list application revisions call to return the next set of application
revisions in the list.









=head2 revisions => ArrayRef[Paws::CodeDeploy::RevisionLocation]

  

A list of revision locations that contain the matching revisions.











=cut

1;