
package Paws::CodeDeploy::ListApplicationsOutput {
  use Moose;
  has applications => (is => 'ro', isa => 'ArrayRef[Str]');
  has nextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodeDeploy::ListApplicationsOutput

=head1 ATTRIBUTES

=head2 applications => ArrayRef[Str]

  

A list of application names.









=head2 nextToken => Str

  

If the amount of information that is returned is significantly large,
an identifier will also be returned, which can be used in a subsequent
list applications call to return the next set of applications in the
list.











=cut

1;