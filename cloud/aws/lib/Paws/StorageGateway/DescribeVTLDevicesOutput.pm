
package Paws::StorageGateway::DescribeVTLDevicesOutput {
  use Moose;
  has GatewayARN => (is => 'ro', isa => 'Str');
  has Marker => (is => 'ro', isa => 'Str');
  has VTLDevices => (is => 'ro', isa => 'ArrayRef[Paws::StorageGateway::VTLDevice]');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::DescribeVTLDevicesOutput

=head1 ATTRIBUTES

=head2 GatewayARN => Str

  
=head2 Marker => Str

  

An opaque string that indicates the position at which the VTL devices
that were fetched for description ended. Use the marker in your next
request to fetch the next set of VTL devices in the list. If there are
no more VTL devices to describe, this field does not appear in the
response.









=head2 VTLDevices => ArrayRef[Paws::StorageGateway::VTLDevice]

  

An array of VTL device objects composed of the Amazon Resource
Name(ARN) of the VTL devices.











=cut

1;