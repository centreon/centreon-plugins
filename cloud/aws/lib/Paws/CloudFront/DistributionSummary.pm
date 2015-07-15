package Paws::CloudFront::DistributionSummary {
  use Moose;
  has Aliases => (is => 'ro', isa => 'Paws::CloudFront::Aliases', required => 1);
  has CacheBehaviors => (is => 'ro', isa => 'Paws::CloudFront::CacheBehaviors', required => 1);
  has Comment => (is => 'ro', isa => 'Str', required => 1);
  has CustomErrorResponses => (is => 'ro', isa => 'Paws::CloudFront::CustomErrorResponses', required => 1);
  has DefaultCacheBehavior => (is => 'ro', isa => 'Paws::CloudFront::DefaultCacheBehavior', required => 1);
  has DomainName => (is => 'ro', isa => 'Str', required => 1);
  has Enabled => (is => 'ro', isa => 'Bool', required => 1);
  has Id => (is => 'ro', isa => 'Str', required => 1);
  has LastModifiedTime => (is => 'ro', isa => 'Str', required => 1);
  has Origins => (is => 'ro', isa => 'Paws::CloudFront::Origins', required => 1);
  has PriceClass => (is => 'ro', isa => 'Str', required => 1);
  has Restrictions => (is => 'ro', isa => 'Paws::CloudFront::Restrictions', required => 1);
  has Status => (is => 'ro', isa => 'Str', required => 1);
  has ViewerCertificate => (is => 'ro', isa => 'Paws::CloudFront::ViewerCertificate', required => 1);
}
1;
