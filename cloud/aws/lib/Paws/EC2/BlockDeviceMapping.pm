package Paws::EC2::BlockDeviceMapping {
  use Moose;
  has DeviceName => (is => 'ro', isa => 'Str', xmlname => 'deviceName', traits => ['Unwrapped']);
  has Ebs => (is => 'ro', isa => 'Paws::EC2::EbsBlockDevice', xmlname => 'ebs', traits => ['Unwrapped']);
  has NoDevice => (is => 'ro', isa => 'Str', xmlname => 'noDevice', traits => ['Unwrapped']);
  has VirtualName => (is => 'ro', isa => 'Str', xmlname => 'virtualName', traits => ['Unwrapped']);
}
1;
