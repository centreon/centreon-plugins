package Paws::CodeDeploy::S3Location {
  use Moose;
  has bucket => (is => 'ro', isa => 'Str');
  has bundleType => (is => 'ro', isa => 'Str');
  has eTag => (is => 'ro', isa => 'Str');
  has key => (is => 'ro', isa => 'Str');
  has version => (is => 'ro', isa => 'Str');
}
1;
