
package Paws::DeviceFarm::GetDevicePoolCompatibilityResult {
  use Moose;
  has compatibleDevices => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::DevicePoolCompatibilityResult]');
  has incompatibleDevices => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::DevicePoolCompatibilityResult]');

}

### main pod documentation begin ###

=head1 NAME

Paws::DeviceFarm::GetDevicePoolCompatibilityResult

=head1 ATTRIBUTES

=head2 compatibleDevices => ArrayRef[Paws::DeviceFarm::DevicePoolCompatibilityResult]

  

Information about compatible devices.









=head2 incompatibleDevices => ArrayRef[Paws::DeviceFarm::DevicePoolCompatibilityResult]

  

Information about incompatible devices.











=cut

1;