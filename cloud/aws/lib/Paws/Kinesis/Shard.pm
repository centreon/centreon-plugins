package Paws::Kinesis::Shard {
  use Moose;
  has AdjacentParentShardId => (is => 'ro', isa => 'Str');
  has HashKeyRange => (is => 'ro', isa => 'Paws::Kinesis::HashKeyRange', required => 1);
  has ParentShardId => (is => 'ro', isa => 'Str');
  has SequenceNumberRange => (is => 'ro', isa => 'Paws::Kinesis::SequenceNumberRange', required => 1);
  has ShardId => (is => 'ro', isa => 'Str', required => 1);
}
1;
