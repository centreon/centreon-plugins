package Paws::DeviceFarm::ProblemDetail {
  use Moose;
  has arn => (is => 'ro', isa => 'Str');
  has name => (is => 'ro', isa => 'Str');
}
1;
