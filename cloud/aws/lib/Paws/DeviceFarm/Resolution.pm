package Paws::DeviceFarm::Resolution {
  use Moose;
  has height => (is => 'ro', isa => 'Int');
  has width => (is => 'ro', isa => 'Int');
}
1;
