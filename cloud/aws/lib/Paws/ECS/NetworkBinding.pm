package Paws::ECS::NetworkBinding {
  use Moose;
  has bindIP => (is => 'ro', isa => 'Str');
  has containerPort => (is => 'ro', isa => 'Int');
  has hostPort => (is => 'ro', isa => 'Int');
  has protocol => (is => 'ro', isa => 'Str');
}
1;
