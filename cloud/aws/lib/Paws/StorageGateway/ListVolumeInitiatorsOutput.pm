
package Paws::StorageGateway::ListVolumeInitiatorsOutput {
  use Moose;
  has Initiators => (is => 'ro', isa => 'ArrayRef[Str]');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::ListVolumeInitiatorsOutput

=head1 ATTRIBUTES

=head2 Initiators => ArrayRef[Str]

  

The host names and port numbers of all iSCSI initiators that are
connected to the gateway.











=cut

1;