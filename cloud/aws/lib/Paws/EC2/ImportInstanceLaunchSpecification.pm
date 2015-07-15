package Paws::EC2::ImportInstanceLaunchSpecification {
  use Moose;
  has AdditionalInfo => (is => 'ro', isa => 'Str', xmlname => 'additionalInfo', traits => ['Unwrapped']);
  has Architecture => (is => 'ro', isa => 'Str', xmlname => 'architecture', traits => ['Unwrapped']);
  has GroupIds => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'GroupId', traits => ['Unwrapped']);
  has GroupNames => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'GroupName', traits => ['Unwrapped']);
  has InstanceInitiatedShutdownBehavior => (is => 'ro', isa => 'Str', xmlname => 'instanceInitiatedShutdownBehavior', traits => ['Unwrapped']);
  has InstanceType => (is => 'ro', isa => 'Str', xmlname => 'instanceType', traits => ['Unwrapped']);
  has Monitoring => (is => 'ro', isa => 'Bool', xmlname => 'monitoring', traits => ['Unwrapped']);
  has Placement => (is => 'ro', isa => 'Paws::EC2::Placement', xmlname => 'placement', traits => ['Unwrapped']);
  has PrivateIpAddress => (is => 'ro', isa => 'Str', xmlname => 'privateIpAddress', traits => ['Unwrapped']);
  has SubnetId => (is => 'ro', isa => 'Str', xmlname => 'subnetId', traits => ['Unwrapped']);
  has UserData => (is => 'ro', isa => 'Paws::EC2::UserData', xmlname => 'userData', traits => ['Unwrapped']);
}
1;
