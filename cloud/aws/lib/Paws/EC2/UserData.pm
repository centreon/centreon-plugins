package Paws::EC2::UserData {
  use Moose;
  has Data => (is => 'ro', isa => 'Str', xmlname => 'data', traits => ['Unwrapped']);
}
1;
