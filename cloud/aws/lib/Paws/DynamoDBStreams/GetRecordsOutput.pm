
package Paws::DynamoDBStreams::GetRecordsOutput {
  use Moose;
  has NextShardIterator => (is => 'ro', isa => 'Str');
  has Records => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDBStreams::Record]');

}

### main pod documentation begin ###

=head1 NAME

Paws::DynamoDBStreams::GetRecordsOutput

=head1 ATTRIBUTES

=head2 NextShardIterator => Str

  

The next position in the shard from which to start sequentially reading
stream records. If set to C<null>, the shard has been closed and the
requested iterator will not return any more data.









=head2 Records => ArrayRef[Paws::DynamoDBStreams::Record]

  

The stream records from the shard, which were retrieved using the shard
iterator.











=cut

1;