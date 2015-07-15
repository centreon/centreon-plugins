package Paws::Glacier::InventoryRetrievalJobInput {
  use Moose;
  has EndDate => (is => 'ro', isa => 'Str');
  has Limit => (is => 'ro', isa => 'Str');
  has Marker => (is => 'ro', isa => 'Str');
  has StartDate => (is => 'ro', isa => 'Str');
}
1;
