package Paws::CloudFront::Origin {
  use Moose;
  has CustomOriginConfig => (is => 'ro', isa => 'Paws::CloudFront::CustomOriginConfig');
  has DomainName => (is => 'ro', isa => 'Str', required => 1);
  has Id => (is => 'ro', isa => 'Str', required => 1);
  has OriginPath => (is => 'ro', isa => 'Str');
  has S3OriginConfig => (is => 'ro', isa => 'Paws::CloudFront::S3OriginConfig');
}
1;
