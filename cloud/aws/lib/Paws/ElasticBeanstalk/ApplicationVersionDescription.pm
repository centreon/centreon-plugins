package Paws::ElasticBeanstalk::ApplicationVersionDescription {
  use Moose;
  has ApplicationName => (is => 'ro', isa => 'Str');
  has DateCreated => (is => 'ro', isa => 'Str');
  has DateUpdated => (is => 'ro', isa => 'Str');
  has Description => (is => 'ro', isa => 'Str');
  has SourceBundle => (is => 'ro', isa => 'Paws::ElasticBeanstalk::S3Location');
  has VersionLabel => (is => 'ro', isa => 'Str');
}
1;
