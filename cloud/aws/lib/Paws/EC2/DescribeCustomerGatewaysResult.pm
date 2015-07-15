
package Paws::EC2::DescribeCustomerGatewaysResult {
  use Moose;
  has CustomerGateways => (is => 'ro', isa => 'ArrayRef[Paws::EC2::CustomerGateway]', xmlname => 'customerGatewaySet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeCustomerGatewaysResult

=head1 ATTRIBUTES

=head2 CustomerGateways => ArrayRef[Paws::EC2::CustomerGateway]

  

Information about one or more customer gateways.











=cut

