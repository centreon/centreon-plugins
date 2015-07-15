package Paws::SDB::ReplaceableAttribute {
  use Moose;
  has Name => (is => 'ro', isa => 'Str', required => 1);
  has Replace => (is => 'ro', isa => 'Bool');
  has Value => (is => 'ro', isa => 'Str', required => 1);
}
1;
