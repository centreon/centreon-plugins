
package Paws::CodeDeploy::GetApplicationRevisionOutput {
  use Moose;
  has applicationName => (is => 'ro', isa => 'Str');
  has revision => (is => 'ro', isa => 'Paws::CodeDeploy::RevisionLocation');
  has revisionInfo => (is => 'ro', isa => 'Paws::CodeDeploy::GenericRevisionInfo');

}

### main pod documentation begin ###

=head1 NAME

Paws::CodeDeploy::GetApplicationRevisionOutput

=head1 ATTRIBUTES

=head2 applicationName => Str

  

The name of the application that corresponds to the revision.









=head2 revision => Paws::CodeDeploy::RevisionLocation

  

Additional information about the revision, including the revision's
type and its location.









=head2 revisionInfo => Paws::CodeDeploy::GenericRevisionInfo

  

General information about the revision.











=cut

1;