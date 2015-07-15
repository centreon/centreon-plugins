
package Paws::EC2::DescribeAddressesResult {
  use Moose;
  has Addresses => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Address]', xmlname => 'addressesSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeAddressesResult

=head1 ATTRIBUTES

=head2 Addresses => ArrayRef[Paws::EC2::Address]

  

Information about one or more Elastic IP addresses.











=cut

