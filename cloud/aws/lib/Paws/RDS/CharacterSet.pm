package Paws::RDS::CharacterSet {
  use Moose;
  has CharacterSetDescription => (is => 'ro', isa => 'Str');
  has CharacterSetName => (is => 'ro', isa => 'Str');
}
1;
