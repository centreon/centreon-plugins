package Paws::IAM::ServerCertificateMetadata {
  use Moose;
  has Arn => (is => 'ro', isa => 'Str', required => 1);
  has Expiration => (is => 'ro', isa => 'Str');
  has Path => (is => 'ro', isa => 'Str', required => 1);
  has ServerCertificateId => (is => 'ro', isa => 'Str', required => 1);
  has ServerCertificateName => (is => 'ro', isa => 'Str', required => 1);
  has UploadDate => (is => 'ro', isa => 'Str');
}
1;
