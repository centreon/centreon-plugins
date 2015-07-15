package Paws::SDB::ReplaceableItem {
  use Moose;
  has Attributes => (is => 'ro', isa => 'ArrayRef[Paws::SDB::ReplaceableAttribute]', required => 1);
  has Name => (is => 'ro', isa => 'Str', xmlname => 'ItemName', request_name => 'ItemName', traits => ['Unwrapped','NameInRequest'], required => 1);
}
1;
