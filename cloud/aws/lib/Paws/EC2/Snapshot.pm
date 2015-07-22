
package Paws::EC2::Snapshot {
  use Moose;
  has Description => (is => 'ro', isa => 'Str', xmlname => 'description', traits => ['Unwrapped',]);
  has Encrypted => (is => 'ro', isa => 'Bool', xmlname => 'encrypted', traits => ['Unwrapped',]);
  has KmsKeyId => (is => 'ro', isa => 'Str', xmlname => 'kmsKeyId', traits => ['Unwrapped',]);
  has OwnerAlias => (is => 'ro', isa => 'Str', xmlname => 'ownerAlias', traits => ['Unwrapped',]);
  has OwnerId => (is => 'ro', isa => 'Str', xmlname => 'ownerId', traits => ['Unwrapped',]);
  has Progress => (is => 'ro', isa => 'Str', xmlname => 'progress', traits => ['Unwrapped',]);
  has SnapshotId => (is => 'ro', isa => 'Str', xmlname => 'snapshotId', traits => ['Unwrapped',]);
  has StartTime => (is => 'ro', isa => 'Str', xmlname => 'startTime', traits => ['Unwrapped',]);
  has State => (is => 'ro', isa => 'Str', xmlname => 'status', traits => ['Unwrapped',]);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', xmlname => 'tagSet', traits => ['Unwrapped',]);
  has VolumeId => (is => 'ro', isa => 'Str', xmlname => 'volumeId', traits => ['Unwrapped',]);
  has VolumeSize => (is => 'ro', isa => 'Int', xmlname => 'volumeSize', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::Snapshot

=head1 ATTRIBUTES

=head2 Description => Str

  

The description for the snapshot.









=head2 Encrypted => Bool

  

Indicates whether the snapshot is encrypted.









=head2 KmsKeyId => Str

  

The full ARN of the AWS Key Management Service (KMS) Customer Master
Key (CMK) that was used to protect the volume encryption key for the
parent volume.









=head2 OwnerAlias => Str

  

The AWS account alias (for example, C<amazon>, C<self>) or AWS account
ID that owns the snapshot.









=head2 OwnerId => Str

  

The AWS account ID of the EBS snapshot owner.









=head2 Progress => Str

  

The progress of the snapshot, as a percentage.









=head2 SnapshotId => Str

  

The ID of the snapshot.









=head2 StartTime => Str

  

The time stamp when the snapshot was initiated.









=head2 State => Str

  

The snapshot state.









=head2 Tags => ArrayRef[Paws::EC2::Tag]

  

Any tags assigned to the snapshot.









=head2 VolumeId => Str

  

The ID of the volume.









=head2 VolumeSize => Int

  

The size of the volume, in GiB.











=cut

