package Paws::DynamoDBStreams::Record {
  use Moose;
  has awsRegion => (is => 'ro', isa => 'Str');
  has dynamodb => (is => 'ro', isa => 'Paws::DynamoDBStreams::StreamRecord');
  has eventID => (is => 'ro', isa => 'Str');
  has eventName => (is => 'ro', isa => 'Str');
  has eventSource => (is => 'ro', isa => 'Str');
  has eventVersion => (is => 'ro', isa => 'Str');
}
1;
