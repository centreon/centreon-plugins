package Paws::DeviceFarm::IncompatibilityMessage {
  use Moose;
  has message => (is => 'ro', isa => 'Str');
  has type => (is => 'ro', isa => 'Str');
}
1;
