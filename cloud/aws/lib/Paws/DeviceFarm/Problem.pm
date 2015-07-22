package Paws::DeviceFarm::Problem {
  use Moose;
  has device => (is => 'ro', isa => 'Paws::DeviceFarm::Device');
  has job => (is => 'ro', isa => 'Paws::DeviceFarm::ProblemDetail');
  has message => (is => 'ro', isa => 'Str');
  has result => (is => 'ro', isa => 'Str');
  has run => (is => 'ro', isa => 'Paws::DeviceFarm::ProblemDetail');
  has suite => (is => 'ro', isa => 'Paws::DeviceFarm::ProblemDetail');
  has test => (is => 'ro', isa => 'Paws::DeviceFarm::ProblemDetail');
}
1;
