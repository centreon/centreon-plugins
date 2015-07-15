
package Paws::Glacier::InitiateMultipartUploadOutput {
  use Moose;
  has location => (is => 'ro', isa => 'Str');
  has uploadId => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Glacier::InitiateMultipartUploadOutput

=head1 ATTRIBUTES

=head2 location => Str

  

The relative URI path of the multipart upload ID Amazon Glacier
created.









=head2 uploadId => Str

  

The ID of the multipart upload. This value is also included as part of
the location.











=cut

