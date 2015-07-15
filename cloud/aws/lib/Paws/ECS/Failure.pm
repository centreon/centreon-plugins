package Paws::ECS::Failure {
  use Moose;
  has arn => (is => 'ro', isa => 'Str');
  has reason => (is => 'ro', isa => 'Str');
}
1;
