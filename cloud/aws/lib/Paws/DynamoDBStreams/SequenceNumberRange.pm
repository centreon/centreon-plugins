package Paws::DynamoDBStreams::SequenceNumberRange {
  use Moose;
  has EndingSequenceNumber => (is => 'ro', isa => 'Str');
  has StartingSequenceNumber => (is => 'ro', isa => 'Str');
}
1;
