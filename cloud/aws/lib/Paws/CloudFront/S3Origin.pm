package Paws::CloudFront::S3Origin {
  use Moose;
  has DomainName => (is => 'ro', isa => 'Str', required => 1);
  has OriginAccessIdentity => (is => 'ro', isa => 'Str', required => 1);
}
1;
