package Paws::DynamoDBStreams::StreamDescription {
  use Moose;
  has CreationRequestDateTime => (is => 'ro', isa => 'Str');
  has KeySchema => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDBStreams::KeySchemaElement]');
  has LastEvaluatedShardId => (is => 'ro', isa => 'Str');
  has Shards => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDBStreams::Shard]');
  has StreamArn => (is => 'ro', isa => 'Str');
  has StreamLabel => (is => 'ro', isa => 'Str');
  has StreamStatus => (is => 'ro', isa => 'Str');
  has StreamViewType => (is => 'ro', isa => 'Str');
  has TableName => (is => 'ro', isa => 'Str');
}
1;
