
package Paws::Kinesis::PutRecordOutput {
  use Moose;
  has SequenceNumber => (is => 'ro', isa => 'Str', required => 1);
  has ShardId => (is => 'ro', isa => 'Str', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::Kinesis::PutRecordOutput

=head1 ATTRIBUTES

=head2 B<REQUIRED> SequenceNumber => Str

  

The sequence number identifier that was assigned to the put data
record. The sequence number for the record is unique across all records
in the stream. A sequence number is the identifier associated with
every record put into the stream.









=head2 B<REQUIRED> ShardId => Str

  

The shard ID of the shard where the data record was placed.











=cut

1;