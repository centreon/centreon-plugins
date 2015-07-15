package Paws::ELB::CrossZoneLoadBalancing {
  use Moose;
  has Enabled => (is => 'ro', isa => 'Bool', required => 1);
}
1;
