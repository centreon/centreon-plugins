package Paws::CloudFront::StreamingDistributionConfig {
  use Moose;
  has Aliases => (is => 'ro', isa => 'Paws::CloudFront::Aliases');
  has CallerReference => (is => 'ro', isa => 'Str', required => 1);
  has Comment => (is => 'ro', isa => 'Str', required => 1);
  has Enabled => (is => 'ro', isa => 'Bool', required => 1);
  has Logging => (is => 'ro', isa => 'Paws::CloudFront::StreamingLoggingConfig');
  has PriceClass => (is => 'ro', isa => 'Str');
  has S3Origin => (is => 'ro', isa => 'Paws::CloudFront::S3Origin', required => 1);
  has TrustedSigners => (is => 'ro', isa => 'Paws::CloudFront::TrustedSigners', required => 1);
}
1;
