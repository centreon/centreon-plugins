package Paws::SSM::AssociationStatus {
  use Moose;
  has AdditionalInfo => (is => 'ro', isa => 'Str');
  has Date => (is => 'ro', isa => 'Str', required => 1);
  has Message => (is => 'ro', isa => 'Str', required => 1);
  has Name => (is => 'ro', isa => 'Str', required => 1);
}
1;
