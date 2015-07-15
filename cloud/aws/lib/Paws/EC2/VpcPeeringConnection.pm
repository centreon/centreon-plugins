package Paws::EC2::VpcPeeringConnection {
  use Moose;
  has AccepterVpcInfo => (is => 'ro', isa => 'Paws::EC2::VpcPeeringConnectionVpcInfo', xmlname => 'accepterVpcInfo', traits => ['Unwrapped']);
  has ExpirationTime => (is => 'ro', isa => 'Str', xmlname => 'expirationTime', traits => ['Unwrapped']);
  has RequesterVpcInfo => (is => 'ro', isa => 'Paws::EC2::VpcPeeringConnectionVpcInfo', xmlname => 'requesterVpcInfo', traits => ['Unwrapped']);
  has Status => (is => 'ro', isa => 'Paws::EC2::VpcPeeringConnectionStateReason', xmlname => 'status', traits => ['Unwrapped']);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', xmlname => 'tagSet', traits => ['Unwrapped']);
  has VpcPeeringConnectionId => (is => 'ro', isa => 'Str', xmlname => 'vpcPeeringConnectionId', traits => ['Unwrapped']);
}
1;
