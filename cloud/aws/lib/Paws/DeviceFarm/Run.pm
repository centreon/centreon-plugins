package Paws::DeviceFarm::Run {
  use Moose;
  has arn => (is => 'ro', isa => 'Str');
  has completedJobs => (is => 'ro', isa => 'Int');
  has counters => (is => 'ro', isa => 'Paws::DeviceFarm::Counters');
  has created => (is => 'ro', isa => 'Str');
  has message => (is => 'ro', isa => 'Str');
  has name => (is => 'ro', isa => 'Str');
  has platform => (is => 'ro', isa => 'Str');
  has result => (is => 'ro', isa => 'Str');
  has started => (is => 'ro', isa => 'Str');
  has status => (is => 'ro', isa => 'Str');
  has stopped => (is => 'ro', isa => 'Str');
  has totalJobs => (is => 'ro', isa => 'Int');
  has type => (is => 'ro', isa => 'Str');
}
1;
