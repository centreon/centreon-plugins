package Paws::EC2::SecurityGroup {
  use Moose;
  has Description => (is => 'ro', isa => 'Str', xmlname => 'groupDescription', traits => ['Unwrapped']);
  has GroupId => (is => 'ro', isa => 'Str', xmlname => 'groupId', traits => ['Unwrapped']);
  has GroupName => (is => 'ro', isa => 'Str', xmlname => 'groupName', traits => ['Unwrapped']);
  has IpPermissions => (is => 'ro', isa => 'ArrayRef[Paws::EC2::IpPermission]', xmlname => 'ipPermissions', traits => ['Unwrapped']);
  has IpPermissionsEgress => (is => 'ro', isa => 'ArrayRef[Paws::EC2::IpPermission]', xmlname => 'ipPermissionsEgress', traits => ['Unwrapped']);
  has OwnerId => (is => 'ro', isa => 'Str', xmlname => 'ownerId', traits => ['Unwrapped']);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', xmlname => 'tagSet', traits => ['Unwrapped']);
  has VpcId => (is => 'ro', isa => 'Str', xmlname => 'vpcId', traits => ['Unwrapped']);
}
1;
