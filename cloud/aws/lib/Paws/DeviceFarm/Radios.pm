package Paws::DeviceFarm::Radios {
  use Moose;
  has bluetooth => (is => 'ro', isa => 'Bool');
  has gps => (is => 'ro', isa => 'Bool');
  has nfc => (is => 'ro', isa => 'Bool');
  has wifi => (is => 'ro', isa => 'Bool');
}
1;
