package Paws::EC2::VolumeDetail {
  use Moose;
  has Size => (is => 'ro', isa => 'Int', xmlname => 'size', traits => ['Unwrapped'], required => 1);
}
1;
