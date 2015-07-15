package Paws::ECS::KeyValuePair {
  use Moose;
  has name => (is => 'ro', isa => 'Str');
  has value => (is => 'ro', isa => 'Str');
}
1;
