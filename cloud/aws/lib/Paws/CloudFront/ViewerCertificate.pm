package Paws::CloudFront::ViewerCertificate {
  use Moose;
  has CloudFrontDefaultCertificate => (is => 'ro', isa => 'Bool');
  has IAMCertificateId => (is => 'ro', isa => 'Str');
  has MinimumProtocolVersion => (is => 'ro', isa => 'Str');
  has SSLSupportMethod => (is => 'ro', isa => 'Str');
}
1;
