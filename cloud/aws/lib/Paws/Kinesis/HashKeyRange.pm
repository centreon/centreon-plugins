package Paws::Kinesis::HashKeyRange {
  use Moose;
  has EndingHashKey => (is => 'ro', isa => 'Str', required => 1);
  has StartingHashKey => (is => 'ro', isa => 'Str', required => 1);
}
1;
