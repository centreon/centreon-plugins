package Paws::CloudWatchLogs::SubscriptionFilter {
  use Moose;
  has creationTime => (is => 'ro', isa => 'Int');
  has destinationArn => (is => 'ro', isa => 'Str');
  has filterName => (is => 'ro', isa => 'Str');
  has filterPattern => (is => 'ro', isa => 'Str');
  has logGroupName => (is => 'ro', isa => 'Str');
  has roleArn => (is => 'ro', isa => 'Str');
}
1;
