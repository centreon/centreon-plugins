package Paws::EC2::RouteTable {
  use Moose;
  has Associations => (is => 'ro', isa => 'ArrayRef[Paws::EC2::RouteTableAssociation]', xmlname => 'associationSet', traits => ['Unwrapped']);
  has PropagatingVgws => (is => 'ro', isa => 'ArrayRef[Paws::EC2::PropagatingVgw]', xmlname => 'propagatingVgwSet', traits => ['Unwrapped']);
  has RouteTableId => (is => 'ro', isa => 'Str', xmlname => 'routeTableId', traits => ['Unwrapped']);
  has Routes => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Route]', xmlname => 'routeSet', traits => ['Unwrapped']);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', xmlname => 'tagSet', traits => ['Unwrapped']);
  has VpcId => (is => 'ro', isa => 'Str', xmlname => 'vpcId', traits => ['Unwrapped']);
}
1;
