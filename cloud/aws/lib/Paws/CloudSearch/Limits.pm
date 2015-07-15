package Paws::CloudSearch::Limits {
  use Moose;
  has MaximumPartitionCount => (is => 'ro', isa => 'Int', required => 1);
  has MaximumReplicationCount => (is => 'ro', isa => 'Int', required => 1);
}
1;
