package Paws::Glacier::JobParameters {
  use Moose;
  has ArchiveId => (is => 'ro', isa => 'Str');
  has Description => (is => 'ro', isa => 'Str');
  has Format => (is => 'ro', isa => 'Str');
  has InventoryRetrievalParameters => (is => 'ro', isa => 'Paws::Glacier::InventoryRetrievalJobInput');
  has RetrievalByteRange => (is => 'ro', isa => 'Str');
  has SNSTopic => (is => 'ro', isa => 'Str');
  has Type => (is => 'ro', isa => 'Str');
}
1;
