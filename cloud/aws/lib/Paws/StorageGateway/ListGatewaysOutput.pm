
package Paws::StorageGateway::ListGatewaysOutput {
  use Moose;
  has Gateways => (is => 'ro', isa => 'ArrayRef[Paws::StorageGateway::GatewayInfo]');
  has Marker => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::ListGatewaysOutput

=head1 ATTRIBUTES

=head2 Gateways => ArrayRef[Paws::StorageGateway::GatewayInfo]

  
=head2 Marker => Str

  


=cut

1;