
package Paws::CloudSearchDomain::UploadDocumentsResponse {
  use Moose;
  has adds => (is => 'ro', isa => 'Int');
  has deletes => (is => 'ro', isa => 'Int');
  has status => (is => 'ro', isa => 'Str');
  has warnings => (is => 'ro', isa => 'ArrayRef[Paws::CloudSearchDomain::DocumentServiceWarning]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearchDomain::UploadDocumentsResponse

=head1 ATTRIBUTES

=head2 adds => Int

  

The number of documents that were added to the search domain.









=head2 deletes => Int

  

The number of documents that were deleted from the search domain.









=head2 status => Str

  

The status of an C<UploadDocumentsRequest>.









=head2 warnings => ArrayRef[Paws::CloudSearchDomain::DocumentServiceWarning]

  

Any warnings returned by the document service about the documents being
uploaded.











=cut

