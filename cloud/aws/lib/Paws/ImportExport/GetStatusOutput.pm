
package Paws::ImportExport::GetStatusOutput {
  use Moose;
  has ArtifactList => (is => 'ro', isa => 'ArrayRef[Paws::ImportExport::Artifact]');
  has Carrier => (is => 'ro', isa => 'Str');
  has CreationDate => (is => 'ro', isa => 'Str');
  has CurrentManifest => (is => 'ro', isa => 'Str');
  has ErrorCount => (is => 'ro', isa => 'Int');
  has JobId => (is => 'ro', isa => 'Str');
  has JobType => (is => 'ro', isa => 'Str');
  has LocationCode => (is => 'ro', isa => 'Str');
  has LocationMessage => (is => 'ro', isa => 'Str');
  has LogBucket => (is => 'ro', isa => 'Str');
  has LogKey => (is => 'ro', isa => 'Str');
  has ProgressCode => (is => 'ro', isa => 'Str');
  has ProgressMessage => (is => 'ro', isa => 'Str');
  has Signature => (is => 'ro', isa => 'Str');
  has SignatureFileContents => (is => 'ro', isa => 'Str');
  has TrackingNumber => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ImportExport::GetStatusOutput

=head1 ATTRIBUTES

=head2 ArtifactList => ArrayRef[Paws::ImportExport::Artifact]

  
=head2 Carrier => Str

  
=head2 CreationDate => Str

  
=head2 CurrentManifest => Str

  
=head2 ErrorCount => Int

  
=head2 JobId => Str

  
=head2 JobType => Str

  
=head2 LocationCode => Str

  
=head2 LocationMessage => Str

  
=head2 LogBucket => Str

  
=head2 LogKey => Str

  
=head2 ProgressCode => Str

  
=head2 ProgressMessage => Str

  
=head2 Signature => Str

  
=head2 SignatureFileContents => Str

  
=head2 TrackingNumber => Str

  


=cut

