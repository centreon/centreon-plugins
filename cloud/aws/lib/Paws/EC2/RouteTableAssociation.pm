package Paws::EC2::RouteTableAssociation {
  use Moose;
  has Main => (is => 'ro', isa => 'Bool', xmlname => 'main', traits => ['Unwrapped']);
  has RouteTableAssociationId => (is => 'ro', isa => 'Str', xmlname => 'routeTableAssociationId', traits => ['Unwrapped']);
  has RouteTableId => (is => 'ro', isa => 'Str', xmlname => 'routeTableId', traits => ['Unwrapped']);
  has SubnetId => (is => 'ro', isa => 'Str', xmlname => 'subnetId', traits => ['Unwrapped']);
}
1;
