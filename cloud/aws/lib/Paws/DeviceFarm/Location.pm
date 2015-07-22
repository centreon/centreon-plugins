package Paws::DeviceFarm::Location {
  use Moose;
  has latitude => (is => 'ro', isa => 'Num', required => 1);
  has longitude => (is => 'ro', isa => 'Num', required => 1);
}
1;
