
package Paws::Kinesis::GetShardIteratorOutput {
  use Moose;
  has ShardIterator => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::Kinesis::GetShardIteratorOutput

=head1 ATTRIBUTES

=head2 ShardIterator => Str

  

The position in the shard from which to start reading data records
sequentially. A shard iterator specifies this position using the
sequence number of a data record in a shard.











=cut

1;