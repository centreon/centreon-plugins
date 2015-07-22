
package Paws::DeviceFarm::ListDevicesResult {
  use Moose;
  has devices => (is => 'ro', isa => 'ArrayRef[Paws::DeviceFarm::Device]');
  has nextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::DeviceFarm::ListDevicesResult

=head1 ATTRIBUTES

=head2 devices => ArrayRef[Paws::DeviceFarm::Device]

  

Information about the devices.









=head2 nextToken => Str

  

If the number of items that are returned is significantly large, this
is an identifier that is also returned, which can be used in a
subsequent call to this operation to return the next set of items in
the list.











=cut

1;