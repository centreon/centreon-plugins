package Paws::RDS::Certificate {
  use Moose;
  has CertificateIdentifier => (is => 'ro', isa => 'Str');
  has CertificateType => (is => 'ro', isa => 'Str');
  has Thumbprint => (is => 'ro', isa => 'Str');
  has ValidFrom => (is => 'ro', isa => 'Str');
  has ValidTill => (is => 'ro', isa => 'Str');
}
1;
