
package Paws::StorageGateway::DescribeVTLDevices {
  use Moose;
  has GatewayARN => (is => 'ro', isa => 'Str', required => 1);
  has Limit => (is => 'ro', isa => 'Int');
  has Marker => (is => 'ro', isa => 'Str');
  has VTLDeviceARNs => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeVTLDevices');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::StorageGateway::DescribeVTLDevicesOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::DescribeVTLDevices - Arguments for method DescribeVTLDevices on Paws::StorageGateway

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeVTLDevices on the 
AWS Storage Gateway service. Use the attributes of this class
as arguments to method DescribeVTLDevices.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeVTLDevices.

As an example:

  $service_obj->DescribeVTLDevices(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> GatewayARN => Str

  

=head2 Limit => Int

  

Specifies that the number of VTL devices described be limited to the
specified number.










=head2 Marker => Str

  

An opaque string that indicates the position at which to begin
describing the VTL devices.










=head2 VTLDeviceARNs => ArrayRef[Str]

  

An array of strings, where each string represents the Amazon Resource
Name (ARN) of a VTL device.

All of the specified VTL devices must be from the same gateway. If no
VTL devices are specified, the result will contain all devices on the
specified gateway.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeVTLDevices in L<Paws::StorageGateway>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

