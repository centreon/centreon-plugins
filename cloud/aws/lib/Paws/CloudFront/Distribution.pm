package Paws::CloudFront::Distribution {
  use Moose;
  has ActiveTrustedSigners => (is => 'ro', isa => 'Paws::CloudFront::ActiveTrustedSigners', required => 1);
  has DistributionConfig => (is => 'ro', isa => 'Paws::CloudFront::DistributionConfig', required => 1);
  has DomainName => (is => 'ro', isa => 'Str', required => 1);
  has Id => (is => 'ro', isa => 'Str', required => 1);
  has InProgressInvalidationBatches => (is => 'ro', isa => 'Int', required => 1);
  has LastModifiedTime => (is => 'ro', isa => 'Str', required => 1);
  has Status => (is => 'ro', isa => 'Str', required => 1);
}
1;
