package Paws::DynamoDBStreams::Shard {
  use Moose;
  has ParentShardId => (is => 'ro', isa => 'Str');
  has SequenceNumberRange => (is => 'ro', isa => 'Paws::DynamoDBStreams::SequenceNumberRange');
  has ShardId => (is => 'ro', isa => 'Str');
}
1;
