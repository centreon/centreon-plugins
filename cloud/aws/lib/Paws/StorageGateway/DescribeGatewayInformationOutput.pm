
package Paws::StorageGateway::DescribeGatewayInformationOutput {
  use Moose;
  has GatewayARN => (is => 'ro', isa => 'Str');
  has GatewayId => (is => 'ro', isa => 'Str');
  has GatewayNetworkInterfaces => (is => 'ro', isa => 'ArrayRef[Paws::StorageGateway::NetworkInterface]');
  has GatewayState => (is => 'ro', isa => 'Str');
  has GatewayTimezone => (is => 'ro', isa => 'Str');
  has GatewayType => (is => 'ro', isa => 'Str');
  has LastSoftwareUpdate => (is => 'ro', isa => 'Str');
  has NextUpdateAvailabilityDate => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::DescribeGatewayInformationOutput

=head1 ATTRIBUTES

=head2 GatewayARN => Str

  
=head2 GatewayId => Str

  

The gateway ID.









=head2 GatewayNetworkInterfaces => ArrayRef[Paws::StorageGateway::NetworkInterface]

  

A NetworkInterface array that contains descriptions of the gateway
network interfaces.









=head2 GatewayState => Str

  

One of the values that indicates the operating state of the gateway.









=head2 GatewayTimezone => Str

  

One of the values that indicates the time zone configured for the
gateway.









=head2 GatewayType => Str

  

The type of the gateway.









=head2 LastSoftwareUpdate => Str

  

The date on which the last software update was applied to the gateway.
If the gateway has never been updated, this field does not return a
value in the response.









=head2 NextUpdateAvailabilityDate => Str

  

The date on which an update to the gateway is available. This date is
in the time zone of the gateway. If the gateway is not available for an
update this field is not returned in the response.











=cut

1;