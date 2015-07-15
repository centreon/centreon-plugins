package Paws::SDB::DeletableItem {
  use Moose;
  has Attributes => (is => 'ro', isa => 'ArrayRef[Paws::SDB::Attribute]');
  has Name => (is => 'ro', isa => 'Str', xmlname => 'ItemName', request_name => 'ItemName', traits => ['Unwrapped','NameInRequest'], required => 1);
}
1;
