package Paws::DeviceFarm::CPU {
  use Moose;
  has architecture => (is => 'ro', isa => 'Str');
  has clock => (is => 'ro', isa => 'Num');
  has frequency => (is => 'ro', isa => 'Str');
}
1;
