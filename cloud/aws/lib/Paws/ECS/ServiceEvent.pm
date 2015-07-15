package Paws::ECS::ServiceEvent {
  use Moose;
  has createdAt => (is => 'ro', isa => 'Str');
  has id => (is => 'ro', isa => 'Str');
  has message => (is => 'ro', isa => 'Str');
}
1;
