package Paws::AutoScaling::LoadBalancerState {
  use Moose;
  has LoadBalancerName => (is => 'ro', isa => 'Str');
  has State => (is => 'ro', isa => 'Str');
}
1;
