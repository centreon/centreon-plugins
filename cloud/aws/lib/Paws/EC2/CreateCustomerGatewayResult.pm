
package Paws::EC2::CreateCustomerGatewayResult {
  use Moose;
  has CustomerGateway => (is => 'ro', isa => 'Paws::EC2::CustomerGateway', xmlname => 'customerGateway', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateCustomerGatewayResult

=head1 ATTRIBUTES

=head2 CustomerGateway => Paws::EC2::CustomerGateway

  

Information about the customer gateway.











=cut

