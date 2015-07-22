package Paws::DeviceFarm::Rule {
  use Moose;
  has attribute => (is => 'ro', isa => 'Str');
  has operator => (is => 'ro', isa => 'Str');
  has value => (is => 'ro', isa => 'Str');
}
1;
