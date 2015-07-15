
package Paws::EC2::CreateVolume {
  use Moose;
  has AvailabilityZone => (is => 'ro', isa => 'Str', required => 1);
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Encrypted => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'encrypted' );
  has Iops => (is => 'ro', isa => 'Int');
  has KmsKeyId => (is => 'ro', isa => 'Str');
  has Size => (is => 'ro', isa => 'Int');
  has SnapshotId => (is => 'ro', isa => 'Str');
  has VolumeType => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateVolume');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::Volume');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateVolume - Arguments for method CreateVolume on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateVolume on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method CreateVolume.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateVolume.

As an example:

  $service_obj->CreateVolume(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> AvailabilityZone => Str

  

The Availability Zone in which to create the volume. Use
DescribeAvailabilityZones to list the Availability Zones that are
currently available to you.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 Encrypted => Bool

  

Specifies whether the volume should be encrypted. Encrypted Amazon EBS
volumes may only be attached to instances that support Amazon EBS
encryption. Volumes that are created from encrypted snapshots are
automatically encrypted. There is no way to create an encrypted volume
from an unencrypted snapshot or vice versa. If your AMI uses encrypted
volumes, you can only launch it on supported instance types. For more
information, see Amazon EBS Encryption in the I<Amazon Elastic Compute
Cloud User Guide>.










=head2 Iops => Int

  

Only valid for Provisioned IOPS (SSD) volumes. The number of I/O
operations per second (IOPS) to provision for the volume, with a
maximum ratio of 30 IOPS/GiB.

Constraint: Range is 100 to 20000 for Provisioned IOPS (SSD) volumes










=head2 KmsKeyId => Str

  

The full ARN of the AWS Key Management Service (KMS) master key to use
when creating the encrypted volume. This parameter is only required if
you want to use a non-default master key; if this parameter is not
specified, the default master key is used. The ARN contains the
C<arn:aws:kms> namespace, followed by the region of the master key, the
AWS account ID of the master key owner, the C<key> namespace, and then
the master key ID. For example,
arn:aws:kms:I<us-east-1>:I<012345678910>:key/I<abcd1234-a123-456a-a12b-a123b4cd56ef>.










=head2 Size => Int

  

The size of the volume, in GiBs.

Constraints: C<1-1024> for C<standard> volumes, C<1-16384> for C<gp2>
volumes, and C<4-16384> for C<io1> volumes. If you specify a snapshot,
the volume size must be equal to or larger than the snapshot size.

Default: If you're creating the volume from a snapshot and don't
specify a volume size, the default is the snapshot size.










=head2 SnapshotId => Str

  

The snapshot from which to create the volume.










=head2 VolumeType => Str

  

The volume type. This can be C<gp2> for General Purpose (SSD) volumes,
C<io1> for Provisioned IOPS (SSD) volumes, or C<standard> for Magnetic
volumes.

Default: C<standard>












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateVolume in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

