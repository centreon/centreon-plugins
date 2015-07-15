package Paws::Config::DeliveryChannel {
  use Moose;
  has name => (is => 'ro', isa => 'Str');
  has s3BucketName => (is => 'ro', isa => 'Str');
  has s3KeyPrefix => (is => 'ro', isa => 'Str');
  has snsTopicARN => (is => 'ro', isa => 'Str');
}
1;
