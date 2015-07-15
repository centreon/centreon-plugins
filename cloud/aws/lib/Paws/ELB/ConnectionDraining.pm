package Paws::ELB::ConnectionDraining {
  use Moose;
  has Enabled => (is => 'ro', isa => 'Bool', required => 1);
  has Timeout => (is => 'ro', isa => 'Int');
}
1;
