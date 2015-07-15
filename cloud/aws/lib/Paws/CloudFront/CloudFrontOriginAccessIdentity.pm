package Paws::CloudFront::CloudFrontOriginAccessIdentity {
  use Moose;
  has CloudFrontOriginAccessIdentityConfig => (is => 'ro', isa => 'Paws::CloudFront::CloudFrontOriginAccessIdentityConfig');
  has Id => (is => 'ro', isa => 'Str', required => 1);
  has S3CanonicalUserId => (is => 'ro', isa => 'Str', required => 1);
}
1;
