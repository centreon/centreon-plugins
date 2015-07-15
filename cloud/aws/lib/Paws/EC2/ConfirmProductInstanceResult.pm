
package Paws::EC2::ConfirmProductInstanceResult {
  use Moose;
  has OwnerId => (is => 'ro', isa => 'Str', xmlname => 'ownerId', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::ConfirmProductInstanceResult

=head1 ATTRIBUTES

=head2 OwnerId => Str

  

The AWS account ID of the instance owner. This is only present if the
product code is attached to the instance.











=cut

