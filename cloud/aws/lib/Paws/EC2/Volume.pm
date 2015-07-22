
package Paws::EC2::Volume {
  use Moose;
  has Attachments => (is => 'ro', isa => 'ArrayRef[Paws::EC2::VolumeAttachment]', xmlname => 'attachmentSet', traits => ['Unwrapped',]);
  has AvailabilityZone => (is => 'ro', isa => 'Str', xmlname => 'availabilityZone', traits => ['Unwrapped',]);
  has CreateTime => (is => 'ro', isa => 'Str', xmlname => 'createTime', traits => ['Unwrapped',]);
  has Encrypted => (is => 'ro', isa => 'Bool', xmlname => 'encrypted', traits => ['Unwrapped',]);
  has Iops => (is => 'ro', isa => 'Int', xmlname => 'iops', traits => ['Unwrapped',]);
  has KmsKeyId => (is => 'ro', isa => 'Str', xmlname => 'kmsKeyId', traits => ['Unwrapped',]);
  has Size => (is => 'ro', isa => 'Int', xmlname => 'size', traits => ['Unwrapped',]);
  has SnapshotId => (is => 'ro', isa => 'Str', xmlname => 'snapshotId', traits => ['Unwrapped',]);
  has State => (is => 'ro', isa => 'Str', xmlname => 'status', traits => ['Unwrapped',]);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', xmlname => 'tagSet', traits => ['Unwrapped',]);
  has VolumeId => (is => 'ro', isa => 'Str', xmlname => 'volumeId', traits => ['Unwrapped',]);
  has VolumeType => (is => 'ro', isa => 'Str', xmlname => 'volumeType', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::Volume

=head1 ATTRIBUTES

=head2 Attachments => ArrayRef[Paws::EC2::VolumeAttachment]

  

Information about the volume attachments.









=head2 AvailabilityZone => Str

  

The Availability Zone for the volume.









=head2 CreateTime => Str

  

The time stamp when volume creation was initiated.









=head2 Encrypted => Bool

  

Indicates whether the volume will be encrypted.









=head2 Iops => Int

  

The number of I/O operations per second (IOPS) that the volume
supports. For Provisioned IOPS (SSD) volumes, this represents the
number of IOPS that are provisioned for the volume. For General Purpose
(SSD) volumes, this represents the baseline performance of the volume
and the rate at which the volume accumulates I/O credits for bursting.
For more information on General Purpose (SSD) baseline performance, I/O
credits, and bursting, see Amazon EBS Volume Types in the I<Amazon
Elastic Compute Cloud User Guide>.

Constraint: Range is 100 to 20000 for Provisioned IOPS (SSD) volumes
and 3 to 10000 for General Purpose (SSD) volumes.

Condition: This parameter is required for requests to create C<io1>
volumes; it is not used in requests to create C<standard> or C<gp2>
volumes.









=head2 KmsKeyId => Str

  

The full ARN of the AWS Key Management Service (KMS) Customer Master
Key (CMK) that was used to protect the volume encryption key for the
volume.









=head2 Size => Int

  

The size of the volume, in GiBs.









=head2 SnapshotId => Str

  

The snapshot from which the volume was created, if applicable.









=head2 State => Str

  

The volume state.









=head2 Tags => ArrayRef[Paws::EC2::Tag]

  

Any tags assigned to the volume.









=head2 VolumeId => Str

  

The ID of the volume.









=head2 VolumeType => Str

  

The volume type. This can be C<gp2> for General Purpose (SSD) volumes,
C<io1> for Provisioned IOPS (SSD) volumes, or C<standard> for Magnetic
volumes.











=cut

