
package Paws::EC2::DescribeDhcpOptionsResult {
  use Moose;
  has DhcpOptions => (is => 'ro', isa => 'ArrayRef[Paws::EC2::DhcpOptions]', xmlname => 'dhcpOptionsSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeDhcpOptionsResult

=head1 ATTRIBUTES

=head2 DhcpOptions => ArrayRef[Paws::EC2::DhcpOptions]

  

Information about one or more DHCP options sets.











=cut

