package Paws::ELB::InstanceState {
  use Moose;
  has Description => (is => 'ro', isa => 'Str');
  has InstanceId => (is => 'ro', isa => 'Str');
  has ReasonCode => (is => 'ro', isa => 'Str');
  has State => (is => 'ro', isa => 'Str');
}
1;
