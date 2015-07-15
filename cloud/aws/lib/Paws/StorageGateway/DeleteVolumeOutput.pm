
package Paws::StorageGateway::DeleteVolumeOutput {
  use Moose;
  has VolumeARN => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::DeleteVolumeOutput

=head1 ATTRIBUTES

=head2 VolumeARN => Str

  

The Amazon Resource Name (ARN) of the storage volume that was deleted.
It is the same ARN you provided in the request.











=cut

1;