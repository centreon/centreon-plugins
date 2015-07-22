
package Paws::EC2::ConfirmProductInstanceResult {
  use Moose;
  has OwnerId => (is => 'ro', isa => 'Str', xmlname => 'ownerId', traits => ['Unwrapped',]);
  has Return => (is => 'ro', isa => 'Bool', xmlname => 'return', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::ConfirmProductInstanceResult

=head1 ATTRIBUTES

=head2 OwnerId => Str

  

The AWS account ID of the instance owner. This is only present if the
product code is attached to the instance.









=head2 Return => Bool

  

The return value of the request. Returns C<true> if the specified
product code is owned by the requester and associated with the
specified instance.











=cut

