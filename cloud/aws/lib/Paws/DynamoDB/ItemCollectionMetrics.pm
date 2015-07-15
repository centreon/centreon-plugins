package Paws::DynamoDB::ItemCollectionMetrics {
  use Moose;
  has ItemCollectionKey => (is => 'ro', isa => 'Paws::DynamoDB::ItemCollectionKeyAttributeMap');
  has SizeEstimateRangeGB => (is => 'ro', isa => 'ArrayRef[Num]');
}
1;
