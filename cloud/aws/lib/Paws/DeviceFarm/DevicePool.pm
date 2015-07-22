package Paws::DeviceFarm::DevicePool {
  use Moose;
  has arn => (is => 'ro', isa => 'Str');
  has description => (is => 'ro', isa => 'Str');
  has name => (is => 'ro', isa => 'Str');
  has rules => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::Rule]');
  has type => (is => 'ro', isa => 'Str');
}
1;
