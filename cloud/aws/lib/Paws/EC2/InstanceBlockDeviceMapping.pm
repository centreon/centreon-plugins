package Paws::EC2::InstanceBlockDeviceMapping {
  use Moose;
  has DeviceName => (is => 'ro', isa => 'Str', xmlname => 'deviceName', traits => ['Unwrapped']);
  has Ebs => (is => 'ro', isa => 'Paws::EC2::EbsInstanceBlockDevice', xmlname => 'ebs', traits => ['Unwrapped']);
}
1;
