package Paws::ELB::ListenerDescription {
  use Moose;
  has Listener => (is => 'ro', isa => 'Paws::ELB::Listener');
  has PolicyNames => (is => 'ro', isa => 'ArrayRef[Str]');
}
1;
