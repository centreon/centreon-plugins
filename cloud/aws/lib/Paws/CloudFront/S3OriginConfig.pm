package Paws::CloudFront::S3OriginConfig {
  use Moose;
  has OriginAccessIdentity => (is => 'ro', isa => 'Str', required => 1);
}
1;
