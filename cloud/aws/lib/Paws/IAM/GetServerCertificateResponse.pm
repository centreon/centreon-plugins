
package Paws::IAM::GetServerCertificateResponse {
  use Moose;
  has ServerCertificate => (is => 'ro', isa => 'Paws::IAM::ServerCertificate', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::GetServerCertificateResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> ServerCertificate => Paws::IAM::ServerCertificate

  

Information about the server certificate.











=cut

