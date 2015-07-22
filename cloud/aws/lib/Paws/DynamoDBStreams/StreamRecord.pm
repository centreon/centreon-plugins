package Paws::DynamoDBStreams::StreamRecord {
  use Moose;
  has Keys => (is => 'ro', isa => 'Paws::DynamoDBStreams::AttributeMap');
  has NewImage => (is => 'ro', isa => 'Paws::DynamoDBStreams::AttributeMap');
  has OldImage => (is => 'ro', isa => 'Paws::DynamoDBStreams::AttributeMap');
  has SequenceNumber => (is => 'ro', isa => 'Str');
  has SizeBytes => (is => 'ro', isa => 'Int');
  has StreamViewType => (is => 'ro', isa => 'Str');
}
1;
