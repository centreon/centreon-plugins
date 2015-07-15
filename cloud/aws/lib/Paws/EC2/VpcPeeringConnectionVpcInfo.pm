package Paws::EC2::VpcPeeringConnectionVpcInfo {
  use Moose;
  has CidrBlock => (is => 'ro', isa => 'Str', xmlname => 'cidrBlock', traits => ['Unwrapped']);
  has OwnerId => (is => 'ro', isa => 'Str', xmlname => 'ownerId', traits => ['Unwrapped']);
  has VpcId => (is => 'ro', isa => 'Str', xmlname => 'vpcId', traits => ['Unwrapped']);
}
1;
