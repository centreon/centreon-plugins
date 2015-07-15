
package Paws::Glacier::ListMultipartUploadsOutput {
  use Moose;
  has Marker => (is => 'ro', isa => 'Str');
  has UploadsList => (is => 'ro', isa => 'ArrayRef[Paws::Glacier::UploadListElement]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Glacier::ListMultipartUploadsOutput

=head1 ATTRIBUTES

=head2 Marker => Str

  

An opaque string that represents where to continue pagination of the
results. You use the marker in a new List Multipart Uploads request to
obtain more uploads in the list. If there are no more uploads, this
value is C<null>.









=head2 UploadsList => ArrayRef[Paws::Glacier::UploadListElement]

  

A list of in-progress multipart uploads.











=cut

