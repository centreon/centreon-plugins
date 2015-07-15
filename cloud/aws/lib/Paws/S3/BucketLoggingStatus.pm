package Paws::S3::BucketLoggingStatus {
  use Moose;
  has LoggingEnabled => (is => 'ro', isa => 'Paws::S3::LoggingEnabled');
}
1;
