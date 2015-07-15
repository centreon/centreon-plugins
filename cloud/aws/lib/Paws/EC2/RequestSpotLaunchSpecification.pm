package Paws::EC2::RequestSpotLaunchSpecification {
  use Moose;
  has AddressingType => (is => 'ro', isa => 'Str', xmlname => 'addressingType', traits => ['Unwrapped']);
  has BlockDeviceMappings => (is => 'ro', isa => 'ArrayRef[Paws::EC2::BlockDeviceMapping]', xmlname => 'blockDeviceMapping', traits => ['Unwrapped']);
  has EbsOptimized => (is => 'ro', isa => 'Bool', xmlname => 'ebsOptimized', traits => ['Unwrapped']);
  has IamInstanceProfile => (is => 'ro', isa => 'Paws::EC2::IamInstanceProfileSpecification', xmlname => 'iamInstanceProfile', traits => ['Unwrapped']);
  has ImageId => (is => 'ro', isa => 'Str', xmlname => 'imageId', traits => ['Unwrapped']);
  has InstanceType => (is => 'ro', isa => 'Str', xmlname => 'instanceType', traits => ['Unwrapped']);
  has KernelId => (is => 'ro', isa => 'Str', xmlname => 'kernelId', traits => ['Unwrapped']);
  has KeyName => (is => 'ro', isa => 'Str', xmlname => 'keyName', traits => ['Unwrapped']);
  has Monitoring => (is => 'ro', isa => 'Paws::EC2::RunInstancesMonitoringEnabled', xmlname => 'monitoring', traits => ['Unwrapped']);
  has NetworkInterfaces => (is => 'ro', isa => 'ArrayRef[Paws::EC2::InstanceNetworkInterfaceSpecification]', xmlname => 'NetworkInterface', traits => ['Unwrapped']);
  has Placement => (is => 'ro', isa => 'Paws::EC2::SpotPlacement', xmlname => 'placement', traits => ['Unwrapped']);
  has RamdiskId => (is => 'ro', isa => 'Str', xmlname => 'ramdiskId', traits => ['Unwrapped']);
  has SecurityGroupIds => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'SecurityGroupId', traits => ['Unwrapped']);
  has SecurityGroups => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'SecurityGroup', traits => ['Unwrapped']);
  has SubnetId => (is => 'ro', isa => 'Str', xmlname => 'subnetId', traits => ['Unwrapped']);
  has UserData => (is => 'ro', isa => 'Str', xmlname => 'userData', traits => ['Unwrapped']);
}
1;
