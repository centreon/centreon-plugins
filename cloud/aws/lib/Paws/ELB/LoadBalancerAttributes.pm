package Paws::ELB::LoadBalancerAttributes {
  use Moose;
  has AccessLog => (is => 'ro', isa => 'Paws::ELB::AccessLog');
  has AdditionalAttributes => (is => 'ro', isa => 'ArrayRef[Paws::ELB::AdditionalAttribute]');
  has ConnectionDraining => (is => 'ro', isa => 'Paws::ELB::ConnectionDraining');
  has ConnectionSettings => (is => 'ro', isa => 'Paws::ELB::ConnectionSettings');
  has CrossZoneLoadBalancing => (is => 'ro', isa => 'Paws::ELB::CrossZoneLoadBalancing');
}
1;
