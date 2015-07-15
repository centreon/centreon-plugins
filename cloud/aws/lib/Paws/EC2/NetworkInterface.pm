package Paws::EC2::NetworkInterface {
  use Moose;
  has Association => (is => 'ro', isa => 'Paws::EC2::NetworkInterfaceAssociation', xmlname => 'association', traits => ['Unwrapped']);
  has Attachment => (is => 'ro', isa => 'Paws::EC2::NetworkInterfaceAttachment', xmlname => 'attachment', traits => ['Unwrapped']);
  has AvailabilityZone => (is => 'ro', isa => 'Str', xmlname => 'availabilityZone', traits => ['Unwrapped']);
  has Description => (is => 'ro', isa => 'Str', xmlname => 'description', traits => ['Unwrapped']);
  has Groups => (is => 'ro', isa => 'ArrayRef[Paws::EC2::GroupIdentifier]', xmlname => 'groupSet', traits => ['Unwrapped']);
  has MacAddress => (is => 'ro', isa => 'Str', xmlname => 'macAddress', traits => ['Unwrapped']);
  has NetworkInterfaceId => (is => 'ro', isa => 'Str', xmlname => 'networkInterfaceId', traits => ['Unwrapped']);
  has OwnerId => (is => 'ro', isa => 'Str', xmlname => 'ownerId', traits => ['Unwrapped']);
  has PrivateDnsName => (is => 'ro', isa => 'Str', xmlname => 'privateDnsName', traits => ['Unwrapped']);
  has PrivateIpAddress => (is => 'ro', isa => 'Str', xmlname => 'privateIpAddress', traits => ['Unwrapped']);
  has PrivateIpAddresses => (is => 'ro', isa => 'ArrayRef[Paws::EC2::NetworkInterfacePrivateIpAddress]', xmlname => 'privateIpAddressesSet', traits => ['Unwrapped']);
  has RequesterId => (is => 'ro', isa => 'Str', xmlname => 'requesterId', traits => ['Unwrapped']);
  has RequesterManaged => (is => 'ro', isa => 'Bool', xmlname => 'requesterManaged', traits => ['Unwrapped']);
  has SourceDestCheck => (is => 'ro', isa => 'Bool', xmlname => 'sourceDestCheck', traits => ['Unwrapped']);
  has Status => (is => 'ro', isa => 'Str', xmlname => 'status', traits => ['Unwrapped']);
  has SubnetId => (is => 'ro', isa => 'Str', xmlname => 'subnetId', traits => ['Unwrapped']);
  has TagSet => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', xmlname => 'tagSet', traits => ['Unwrapped']);
  has VpcId => (is => 'ro', isa => 'Str', xmlname => 'vpcId', traits => ['Unwrapped']);
}
1;
