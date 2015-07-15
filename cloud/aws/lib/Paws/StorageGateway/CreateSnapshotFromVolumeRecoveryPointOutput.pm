
package Paws::StorageGateway::CreateSnapshotFromVolumeRecoveryPointOutput {
  use Moose;
  has SnapshotId => (is => 'ro', isa => 'Str');
  has VolumeARN => (is => 'ro', isa => 'Str');
  has VolumeRecoveryPointTime => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::CreateSnapshotFromVolumeRecoveryPointOutput

=head1 ATTRIBUTES

=head2 SnapshotId => Str

  
=head2 VolumeARN => Str

  
=head2 VolumeRecoveryPointTime => Str

  


=cut

1;