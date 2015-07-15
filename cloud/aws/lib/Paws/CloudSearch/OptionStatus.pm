package Paws::CloudSearch::OptionStatus {
  use Moose;
  has CreationDate => (is => 'ro', isa => 'Str', required => 1);
  has PendingDeletion => (is => 'ro', isa => 'Bool');
  has State => (is => 'ro', isa => 'Str', required => 1);
  has UpdateDate => (is => 'ro', isa => 'Str', required => 1);
  has UpdateVersion => (is => 'ro', isa => 'Int');
}
1;
