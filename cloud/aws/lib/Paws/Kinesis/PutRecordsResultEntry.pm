package Paws::Kinesis::PutRecordsResultEntry {
  use Moose;
  has ErrorCode => (is => 'ro', isa => 'Str');
  has ErrorMessage => (is => 'ro', isa => 'Str');
  has SequenceNumber => (is => 'ro', isa => 'Str');
  has ShardId => (is => 'ro', isa => 'Str');
}
1;
