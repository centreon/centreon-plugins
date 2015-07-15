
package Paws::EC2::DescribeNetworkInterfacesResult {
  use Moose;
  has NetworkInterfaces => (is => 'ro', isa => 'ArrayRef[Paws::EC2::NetworkInterface]', xmlname => 'networkInterfaceSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeNetworkInterfacesResult

=head1 ATTRIBUTES

=head2 NetworkInterfaces => ArrayRef[Paws::EC2::NetworkInterface]

  

Information about one or more network interfaces.











=cut

