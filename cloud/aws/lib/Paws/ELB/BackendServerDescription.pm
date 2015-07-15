package Paws::ELB::BackendServerDescription {
  use Moose;
  has InstancePort => (is => 'ro', isa => 'Int');
  has PolicyNames => (is => 'ro', isa => 'ArrayRef[Str]');
}
1;
