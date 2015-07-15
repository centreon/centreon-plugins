package Paws::Kinesis::SequenceNumberRange {
  use Moose;
  has EndingSequenceNumber => (is => 'ro', isa => 'Str');
  has StartingSequenceNumber => (is => 'ro', isa => 'Str', required => 1);
}
1;
