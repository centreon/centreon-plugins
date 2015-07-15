
package Paws::DirectConnect::VirtualGateways {
  use Moose;
  has virtualGateways => (is => 'ro', isa => 'ArrayRef[Paws::DirectConnect::VirtualGateway]');

}

### main pod documentation begin ###

=head1 NAME

Paws::DirectConnect::VirtualGateways

=head1 ATTRIBUTES

=head2 virtualGateways => ArrayRef[Paws::DirectConnect::VirtualGateway]

  

A list of virtual private gateways.











=cut

1;