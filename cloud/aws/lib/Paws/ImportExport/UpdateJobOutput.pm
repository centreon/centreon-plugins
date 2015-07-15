
package Paws::ImportExport::UpdateJobOutput {
  use Moose;
  has ArtifactList => (is => 'ro', isa => 'ArrayRef[Paws::ImportExport::Artifact]');
  has Success => (is => 'ro', isa => 'Bool');
  has WarningMessage => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ImportExport::UpdateJobOutput

=head1 ATTRIBUTES

=head2 ArtifactList => ArrayRef[Paws::ImportExport::Artifact]

  
=head2 Success => Bool

  
=head2 WarningMessage => Str

  


=cut

