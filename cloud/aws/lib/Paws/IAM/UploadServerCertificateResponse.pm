
package Paws::IAM::UploadServerCertificateResponse {
  use Moose;
  has ServerCertificateMetadata => (is => 'ro', isa => 'Paws::IAM::ServerCertificateMetadata');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::UploadServerCertificateResponse

=head1 ATTRIBUTES

=head2 ServerCertificateMetadata => Paws::IAM::ServerCertificateMetadata

  

The meta information of the uploaded server certificate without its
certificate body, certificate chain, and private key.











=cut

