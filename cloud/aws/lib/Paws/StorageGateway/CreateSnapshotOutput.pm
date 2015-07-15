
package Paws::StorageGateway::CreateSnapshotOutput {
  use Moose;
  has SnapshotId => (is => 'ro', isa => 'Str');
  has VolumeARN => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::CreateSnapshotOutput

=head1 ATTRIBUTES

=head2 SnapshotId => Str

  

The snapshot ID that is used to refer to the snapshot in future
operations such as describing snapshots (Amazon Elastic Compute Cloud
API C<DescribeSnapshots>) or creating a volume from a snapshot
(CreateStorediSCSIVolume).









=head2 VolumeARN => Str

  

The Amazon Resource Name (ARN) of the volume of which the snapshot was
taken.











=cut

1;