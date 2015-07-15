package Paws::CloudFront::CloudFrontOriginAccessIdentityConfig {
  use Moose;
  has CallerReference => (is => 'ro', isa => 'Str', required => 1);
  has Comment => (is => 'ro', isa => 'Str', required => 1);
}
1;
