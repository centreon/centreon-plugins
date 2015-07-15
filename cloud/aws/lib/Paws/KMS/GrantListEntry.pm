package Paws::KMS::GrantListEntry {
  use Moose;
  has Constraints => (is => 'ro', isa => 'Paws::KMS::GrantConstraints');
  has GrantId => (is => 'ro', isa => 'Str');
  has GranteePrincipal => (is => 'ro', isa => 'Str');
  has IssuingAccount => (is => 'ro', isa => 'Str');
  has Operations => (is => 'ro', isa => 'ArrayRef[Str]');
  has RetiringPrincipal => (is => 'ro', isa => 'Str');
}
1;
