package Paws::ElasticBeanstalk::S3Location {
  use Moose;
  has S3Bucket => (is => 'ro', isa => 'Str');
  has S3Key => (is => 'ro', isa => 'Str');
}
1;
