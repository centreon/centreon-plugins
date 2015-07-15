package Paws::CloudFront::LoggingConfig {
  use Moose;
  has Bucket => (is => 'ro', isa => 'Str', required => 1);
  has Enabled => (is => 'ro', isa => 'Bool', required => 1);
  has IncludeCookies => (is => 'ro', isa => 'Bool', required => 1);
  has Prefix => (is => 'ro', isa => 'Str', required => 1);
}
1;
