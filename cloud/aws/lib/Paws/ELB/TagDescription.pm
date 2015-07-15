package Paws::ELB::TagDescription {
  use Moose;
  has LoadBalancerName => (is => 'ro', isa => 'Str');
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::ELB::Tag]');
}
1;
