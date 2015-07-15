package Paws::StorageGateway::VTLDevice {
  use Moose;
  has DeviceiSCSIAttributes => (is => 'ro', isa => 'Paws::StorageGateway::DeviceiSCSIAttributes');
  has VTLDeviceARN => (is => 'ro', isa => 'Str');
  has VTLDeviceProductIdentifier => (is => 'ro', isa => 'Str');
  has VTLDeviceType => (is => 'ro', isa => 'Str');
  has VTLDeviceVendor => (is => 'ro', isa => 'Str');
}
1;
