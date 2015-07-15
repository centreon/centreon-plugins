package Paws::SDB::UpdateCondition {
  use Moose;
  has Exists => (is => 'ro', isa => 'Bool');
  has Name => (is => 'ro', isa => 'Str');
  has Value => (is => 'ro', isa => 'Str');
}
1;
