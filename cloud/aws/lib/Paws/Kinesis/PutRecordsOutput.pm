
package Paws::Kinesis::PutRecordsOutput {
  use Moose;
  has FailedRecordCount => (is => 'ro', isa => 'Int');
  has Records => (is => 'ro', isa => 'ArrayRef[Paws::Kinesis::PutRecordsResultEntry]', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::Kinesis::PutRecordsOutput

=head1 ATTRIBUTES

=head2 FailedRecordCount => Int

  

The number of unsuccessfully processed records in a C<PutRecords>
request.









=head2 B<REQUIRED> Records => ArrayRef[Paws::Kinesis::PutRecordsResultEntry]

  

An array of successfully and unsuccessfully processed record results,
correlated with the request by natural ordering. A record that is
successfully added to your Amazon Kinesis stream includes
C<SequenceNumber> and C<ShardId> in the result. A record that fails to
be added to your Amazon Kinesis stream includes C<ErrorCode> and
C<ErrorMessage> in the result.











=cut

1;