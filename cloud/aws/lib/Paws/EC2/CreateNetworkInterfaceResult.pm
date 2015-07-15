
package Paws::EC2::CreateNetworkInterfaceResult {
  use Moose;
  has NetworkInterface => (is => 'ro', isa => 'Paws::EC2::NetworkInterface', xmlname => 'networkInterface', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateNetworkInterfaceResult

=head1 ATTRIBUTES

=head2 NetworkInterface => Paws::EC2::NetworkInterface

  

Information about the network interface.











=cut

