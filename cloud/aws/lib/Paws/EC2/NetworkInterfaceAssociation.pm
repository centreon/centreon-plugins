package Paws::EC2::NetworkInterfaceAssociation {
  use Moose;
  has AllocationId => (is => 'ro', isa => 'Str', xmlname => 'allocationId', traits => ['Unwrapped']);
  has AssociationId => (is => 'ro', isa => 'Str', xmlname => 'associationId', traits => ['Unwrapped']);
  has IpOwnerId => (is => 'ro', isa => 'Str', xmlname => 'ipOwnerId', traits => ['Unwrapped']);
  has PublicDnsName => (is => 'ro', isa => 'Str', xmlname => 'publicDnsName', traits => ['Unwrapped']);
  has PublicIp => (is => 'ro', isa => 'Str', xmlname => 'publicIp', traits => ['Unwrapped']);
}
1;
