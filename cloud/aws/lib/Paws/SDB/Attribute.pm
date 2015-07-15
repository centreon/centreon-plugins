package Paws::SDB::Attribute {
  use Moose;
  has AlternateNameEncoding => (is => 'ro', isa => 'Str');
  has AlternateValueEncoding => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str', required => 1);
  has Value => (is => 'ro', isa => 'Str', required => 1);
}
1;
