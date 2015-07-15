package Paws::EC2::Subnet {
  use Moose;
  has AvailabilityZone => (is => 'ro', isa => 'Str', xmlname => 'availabilityZone', traits => ['Unwrapped']);
  has AvailableIpAddressCount => (is => 'ro', isa => 'Int', xmlname => 'availableIpAddressCount', traits => ['Unwrapped']);
  has CidrBlock => (is => 'ro', isa => 'Str', xmlname => 'cidrBlock', traits => ['Unwrapped']);
  has DefaultForAz => (is => 'ro', isa => 'Bool', xmlname => 'defaultForAz', traits => ['Unwrapped']);
  has MapPublicIpOnLaunch => (is => 'ro', isa => 'Bool', xmlname => 'mapPublicIpOnLaunch', traits => ['Unwrapped']);
  has State => (is => 'ro', isa => 'Str', xmlname => 'state', traits => ['Unwrapped']);
  has SubnetId => (is => 'ro', isa => 'Str', xmlname => 'subnetId', traits => ['Unwrapped']);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', xmlname => 'tagSet', traits => ['Unwrapped']);
  has VpcId => (is => 'ro', isa => 'Str', xmlname => 'vpcId', traits => ['Unwrapped']);
}
1;
