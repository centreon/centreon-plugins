package Paws::DeviceFarm::DevicePoolCompatibilityResult {
  use Moose;
  has compatible => (is => 'ro', isa => 'Bool');
  has device => (is => 'ro', isa => 'Paws::DeviceFarm::Device');
  has incompatibilityMessages => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::IncompatibilityMessage]');
}
1;
