package Paws::ElastiCache::NotificationConfiguration {
  use Moose;
  has TopicArn => (is => 'ro', isa => 'Str');
  has TopicStatus => (is => 'ro', isa => 'Str');
}
1;
