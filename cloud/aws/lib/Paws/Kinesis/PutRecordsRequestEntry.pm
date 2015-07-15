package Paws::Kinesis::PutRecordsRequestEntry {
  use Moose;
  has Data => (is => 'ro', isa => 'Str', required => 1);
  has ExplicitHashKey => (is => 'ro', isa => 'Str');
  has PartitionKey => (is => 'ro', isa => 'Str', required => 1);
}
1;
