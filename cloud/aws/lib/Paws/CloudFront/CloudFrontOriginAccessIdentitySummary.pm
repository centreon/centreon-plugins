package Paws::CloudFront::CloudFrontOriginAccessIdentitySummary {
  use Moose;
  has Comment => (is => 'ro', isa => 'Str', required => 1);
  has Id => (is => 'ro', isa => 'Str', required => 1);
  has S3CanonicalUserId => (is => 'ro', isa => 'Str', required => 1);
}
1;
