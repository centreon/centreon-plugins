package Paws::EC2::InstanceNetworkInterfaceSpecification {
  use Moose;
  has AssociatePublicIpAddress => (is => 'ro', isa => 'Bool', xmlname => 'associatePublicIpAddress', traits => ['Unwrapped']);
  has DeleteOnTermination => (is => 'ro', isa => 'Bool', xmlname => 'deleteOnTermination', traits => ['Unwrapped']);
  has Description => (is => 'ro', isa => 'Str', xmlname => 'description', traits => ['Unwrapped']);
  has DeviceIndex => (is => 'ro', isa => 'Int', xmlname => 'deviceIndex', traits => ['Unwrapped']);
  has Groups => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'SecurityGroupId', traits => ['Unwrapped']);
  has NetworkInterfaceId => (is => 'ro', isa => 'Str', xmlname => 'networkInterfaceId', traits => ['Unwrapped']);
  has PrivateIpAddress => (is => 'ro', isa => 'Str', xmlname => 'privateIpAddress', traits => ['Unwrapped']);
  has PrivateIpAddresses => (is => 'ro', isa => 'ArrayRef[Paws::EC2::PrivateIpAddressSpecification]', xmlname => 'privateIpAddressesSet', traits => ['Unwrapped']);
  has SecondaryPrivateIpAddressCount => (is => 'ro', isa => 'Int', xmlname => 'secondaryPrivateIpAddressCount', traits => ['Unwrapped']);
  has SubnetId => (is => 'ro', isa => 'Str', xmlname => 'subnetId', traits => ['Unwrapped']);
}
1;
