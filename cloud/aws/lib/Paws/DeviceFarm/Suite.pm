package Paws::DeviceFarm::Suite {
  use Moose;
  has arn => (is => 'ro', isa => 'Str');
  has counters => (is => 'ro', isa => 'Paws::DeviceFarm::Counters');
  has created => (is => 'ro', isa => 'Str');
  has message => (is => 'ro', isa => 'Str');
  has name => (is => 'ro', isa => 'Str');
  has result => (is => 'ro', isa => 'Str');
  has started => (is => 'ro', isa => 'Str');
  has status => (is => 'ro', isa => 'Str');
  has stopped => (is => 'ro', isa => 'Str');
  has type => (is => 'ro', isa => 'Str');
}
1;
