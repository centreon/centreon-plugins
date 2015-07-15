
package Paws::Glacier::ArchiveCreationOutput {
  use Moose;
  has archiveId => (is => 'ro', isa => 'Str');
  has checksum => (is => 'ro', isa => 'Str');
  has location => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Glacier::ArchiveCreationOutput

=head1 ATTRIBUTES

=head2 archiveId => Str

  

The ID of the archive. This value is also included as part of the
location.









=head2 checksum => Str

  

The checksum of the archive computed by Amazon Glacier.









=head2 location => Str

  

The relative URI path of the newly added archive resource.











=cut

