
package Paws::IAM::UploadSigningCertificateResponse {
  use Moose;
  has Certificate => (is => 'ro', isa => 'Paws::IAM::SigningCertificate', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::UploadSigningCertificateResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> Certificate => Paws::IAM::SigningCertificate

  

Information about the certificate.











=cut

