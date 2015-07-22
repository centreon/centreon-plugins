package Paws::DeviceFarm::Sample {
  use Moose;
  has arn => (is => 'ro', isa => 'Str');
  has type => (is => 'ro', isa => 'Str');
  has url => (is => 'ro', isa => 'Str');
}
1;
