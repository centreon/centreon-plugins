
package Paws::DeviceFarm::ListDevicePoolsResult {
  use Moose;
  has devicePools => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::DevicePool]');
  has nextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::DeviceFarm::ListDevicePoolsResult

=head1 ATTRIBUTES

=head2 devicePools => ArrayRef[Paws::DeviceFarm::DevicePool]

  

Information about the device pools.









=head2 nextToken => Str

  

If the number of items that are returned is significantly large, this
is an identifier that is also returned, which can be used in a
subsequent call to this operation to return the next set of items in
the list.











=cut

1;