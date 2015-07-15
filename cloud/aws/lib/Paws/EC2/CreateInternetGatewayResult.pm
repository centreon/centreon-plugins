
package Paws::EC2::CreateInternetGatewayResult {
  use Moose;
  has InternetGateway => (is => 'ro', isa => 'Paws::EC2::InternetGateway', xmlname => 'internetGateway', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateInternetGatewayResult

=head1 ATTRIBUTES

=head2 InternetGateway => Paws::EC2::InternetGateway

  

Information about the Internet gateway.











=cut

