package Paws::EC2::UnsuccessfulItem {
  use Moose;
  has Error => (is => 'ro', isa => 'Paws::EC2::UnsuccessfulItemError', xmlname => 'error', traits => ['Unwrapped'], required => 1);
  has ResourceId => (is => 'ro', isa => 'Str', xmlname => 'resourceId', traits => ['Unwrapped']);
}
1;
