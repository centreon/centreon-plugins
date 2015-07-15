package Paws::ECS::PortMapping {
  use Moose;
  has containerPort => (is => 'ro', isa => 'Int');
  has hostPort => (is => 'ro', isa => 'Int');
  has protocol => (is => 'ro', isa => 'Str');
}
1;
