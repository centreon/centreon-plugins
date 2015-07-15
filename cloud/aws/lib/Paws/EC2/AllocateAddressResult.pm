
package Paws::EC2::AllocateAddressResult {
  use Moose;
  has AllocationId => (is => 'ro', isa => 'Str', xmlname => 'allocationId', traits => ['Unwrapped',]);
  has Domain => (is => 'ro', isa => 'Str', xmlname => 'domain', traits => ['Unwrapped',]);
  has PublicIp => (is => 'ro', isa => 'Str', xmlname => 'publicIp', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::AllocateAddressResult

=head1 ATTRIBUTES

=head2 AllocationId => Str

  

[EC2-VPC] The ID that AWS assigns to represent the allocation of the
Elastic IP address for use with instances in a VPC.









=head2 Domain => Str

  

Indicates whether this Elastic IP address is for use with instances in
EC2-Classic (C<standard>) or instances in a VPC (C<vpc>).









=head2 PublicIp => Str

  

The Elastic IP address.











=cut

