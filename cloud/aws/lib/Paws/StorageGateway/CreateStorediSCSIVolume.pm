
package Paws::StorageGateway::CreateStorediSCSIVolume {
  use Moose;
  has DiskId => (is => 'ro', isa => 'Str', required => 1);
  has GatewayARN => (is => 'ro', isa => 'Str', required => 1);
  has NetworkInterfaceId => (is => 'ro', isa => 'Str', required => 1);
  has PreserveExistingData => (is => 'ro', isa => 'Bool', required => 1);
  has SnapshotId => (is => 'ro', isa => 'Str');
  has TargetName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateStorediSCSIVolume');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::StorageGateway::CreateStorediSCSIVolumeOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::CreateStorediSCSIVolume - Arguments for method CreateStorediSCSIVolume on Paws::StorageGateway

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateStorediSCSIVolume on the 
AWS Storage Gateway service. Use the attributes of this class
as arguments to method CreateStorediSCSIVolume.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateStorediSCSIVolume.

As an example:

  $service_obj->CreateStorediSCSIVolume(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DiskId => Str

  

The unique identifier for the gateway local disk that is configured as
a stored volume. Use ListLocalDisks to list disk IDs for a gateway.










=head2 B<REQUIRED> GatewayARN => Str

  

=head2 B<REQUIRED> NetworkInterfaceId => Str

  

The network interface of the gateway on which to expose the iSCSI
target. Only IPv4 addresses are accepted. Use
DescribeGatewayInformation to get a list of the network interfaces
available on a gateway.

I<Valid Values>: A valid IP address.










=head2 B<REQUIRED> PreserveExistingData => Bool

  

Specify this field as true if you want to preserve the data on the
local disk. Otherwise, specifying this field as false creates an empty
volume.

I<Valid Values>: true, false










=head2 SnapshotId => Str

  

The snapshot ID (e.g. "snap-1122aabb") of the snapshot to restore as
the new stored volume. Specify this field if you want to create the
iSCSI storage volume from a snapshot otherwise do not include this
field. To list snapshots for your account use DescribeSnapshots in the
I<Amazon Elastic Compute Cloud API Reference>.










=head2 B<REQUIRED> TargetName => Str

  

The name of the iSCSI target used by initiators to connect to the
target and as a suffix for the target ARN. For example, specifying
C<TargetName> as I<myvolume> results in the target ARN of
arn:aws:storagegateway:us-east-1:111122223333:gateway/mygateway/target/iqn.1997-05.com.amazon:myvolume.
The target name must be unique across all volumes of a gateway.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateStorediSCSIVolume in L<Paws::StorageGateway>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

