package Paws::SDB::Item {
  use Moose;
  has AlternateNameEncoding => (is => 'ro', isa => 'Str');
  has Attributes => (is => 'ro', isa => 'ArrayRef[Paws::SDB::Attribute]', required => 1);
  has Name => (is => 'ro', isa => 'Str', required => 1);
}
1;
