package Paws::EC2::Vpc {
  use Moose;
  has CidrBlock => (is => 'ro', isa => 'Str', xmlname => 'cidrBlock', traits => ['Unwrapped']);
  has DhcpOptionsId => (is => 'ro', isa => 'Str', xmlname => 'dhcpOptionsId', traits => ['Unwrapped']);
  has InstanceTenancy => (is => 'ro', isa => 'Str', xmlname => 'instanceTenancy', traits => ['Unwrapped']);
  has IsDefault => (is => 'ro', isa => 'Bool', xmlname => 'isDefault', traits => ['Unwrapped']);
  has State => (is => 'ro', isa => 'Str', xmlname => 'state', traits => ['Unwrapped']);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', xmlname => 'tagSet', traits => ['Unwrapped']);
  has VpcId => (is => 'ro', isa => 'Str', xmlname => 'vpcId', traits => ['Unwrapped']);
}
1;
