package Paws::AutoScaling::NotificationConfiguration {
  use Moose;
  has AutoScalingGroupName => (is => 'ro', isa => 'Str');
  has NotificationType => (is => 'ro', isa => 'Str');
  has TopicARN => (is => 'ro', isa => 'Str');
}
1;
