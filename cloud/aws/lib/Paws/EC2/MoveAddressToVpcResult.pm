
package Paws::EC2::MoveAddressToVpcResult {
  use Moose;
  has AllocationId => (is => 'ro', isa => 'Str', xmlname => 'allocationId', traits => ['Unwrapped',]);
  has Status => (is => 'ro', isa => 'Str', xmlname => 'status', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::MoveAddressToVpcResult

=head1 ATTRIBUTES

=head2 AllocationId => Str

  

The allocation ID for the Elastic IP address.









=head2 Status => Str

  

The status of the move of the IP address.











=cut

