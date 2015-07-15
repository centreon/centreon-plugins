package Paws::ECS::LoadBalancer {
  use Moose;
  has containerName => (is => 'ro', isa => 'Str');
  has containerPort => (is => 'ro', isa => 'Int');
  has loadBalancerName => (is => 'ro', isa => 'Str');
}
1;
