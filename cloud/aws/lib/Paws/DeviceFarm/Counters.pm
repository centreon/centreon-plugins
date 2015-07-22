package Paws::DeviceFarm::Counters {
  use Moose;
  has errored => (is => 'ro', isa => 'Int');
  has failed => (is => 'ro', isa => 'Int');
  has passed => (is => 'ro', isa => 'Int');
  has skipped => (is => 'ro', isa => 'Int');
  has stopped => (is => 'ro', isa => 'Int');
  has total => (is => 'ro', isa => 'Int');
  has warned => (is => 'ro', isa => 'Int');
}
1;
