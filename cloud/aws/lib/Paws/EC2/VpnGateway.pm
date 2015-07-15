package Paws::EC2::VpnGateway {
  use Moose;
  has AvailabilityZone => (is => 'ro', isa => 'Str', xmlname => 'availabilityZone', traits => ['Unwrapped']);
  has State => (is => 'ro', isa => 'Str', xmlname => 'state', traits => ['Unwrapped']);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', xmlname => 'tagSet', traits => ['Unwrapped']);
  has Type => (is => 'ro', isa => 'Str', xmlname => 'type', traits => ['Unwrapped']);
  has VpcAttachments => (is => 'ro', isa => 'ArrayRef[Paws::EC2::VpcAttachment]', xmlname => 'attachments', traits => ['Unwrapped']);
  has VpnGatewayId => (is => 'ro', isa => 'Str', xmlname => 'vpnGatewayId', traits => ['Unwrapped']);
}
1;
