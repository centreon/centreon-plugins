package Paws::DeviceFarm::Project {
  use Moose;
  has arn => (is => 'ro', isa => 'Str');
  has created => (is => 'ro', isa => 'Str');
  has name => (is => 'ro', isa => 'Str');
}
1;
