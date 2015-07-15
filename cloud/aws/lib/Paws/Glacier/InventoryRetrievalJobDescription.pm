package Paws::Glacier::InventoryRetrievalJobDescription {
  use Moose;
  has EndDate => (is => 'ro', isa => 'Str');
  has Format => (is => 'ro', isa => 'Str');
  has Limit => (is => 'ro', isa => 'Str');
  has Marker => (is => 'ro', isa => 'Str');
  has StartDate => (is => 'ro', isa => 'Str');
}
1;
