package Paws::StorageGateway {
  use Moose;
  sub service { 'storagegateway' }
  sub version { '2013-06-30' }
  sub target_prefix { 'StorageGateway_20130630' }
  sub json_version { "1.1" }

  with 'Paws::API::Caller', 'Paws::API::RegionalEndpointCaller', 'Paws::Net::V4Signature', 'Paws::Net::JsonCaller', 'Paws::Net::JsonResponse';

  
  sub ActivateGateway {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::ActivateGateway', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AddCache {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::AddCache', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AddUploadBuffer {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::AddUploadBuffer', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AddWorkingStorage {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::AddWorkingStorage', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CancelArchival {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::CancelArchival', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CancelRetrieval {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::CancelRetrieval', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateCachediSCSIVolume {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::CreateCachediSCSIVolume', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateSnapshot {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::CreateSnapshot', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateSnapshotFromVolumeRecoveryPoint {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::CreateSnapshotFromVolumeRecoveryPoint', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateStorediSCSIVolume {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::CreateStorediSCSIVolume', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateTapes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::CreateTapes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteBandwidthRateLimit {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DeleteBandwidthRateLimit', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteChapCredentials {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DeleteChapCredentials', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteGateway {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DeleteGateway', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteSnapshotSchedule {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DeleteSnapshotSchedule', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteTape {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DeleteTape', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteTapeArchive {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DeleteTapeArchive', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteVolume {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DeleteVolume', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeBandwidthRateLimit {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DescribeBandwidthRateLimit', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeCache {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DescribeCache', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeCachediSCSIVolumes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DescribeCachediSCSIVolumes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeChapCredentials {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DescribeChapCredentials', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeGatewayInformation {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DescribeGatewayInformation', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeMaintenanceStartTime {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DescribeMaintenanceStartTime', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeSnapshotSchedule {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DescribeSnapshotSchedule', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeStorediSCSIVolumes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DescribeStorediSCSIVolumes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeTapeArchives {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DescribeTapeArchives', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeTapeRecoveryPoints {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DescribeTapeRecoveryPoints', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeTapes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DescribeTapes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeUploadBuffer {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DescribeUploadBuffer', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeVTLDevices {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DescribeVTLDevices', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeWorkingStorage {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DescribeWorkingStorage', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DisableGateway {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::DisableGateway', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListGateways {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::ListGateways', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListLocalDisks {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::ListLocalDisks', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListVolumeInitiators {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::ListVolumeInitiators', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListVolumeRecoveryPoints {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::ListVolumeRecoveryPoints', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListVolumes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::ListVolumes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ResetCache {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::ResetCache', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RetrieveTapeArchive {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::RetrieveTapeArchive', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RetrieveTapeRecoveryPoint {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::RetrieveTapeRecoveryPoint', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ShutdownGateway {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::ShutdownGateway', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub StartGateway {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::StartGateway', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateBandwidthRateLimit {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::UpdateBandwidthRateLimit', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateChapCredentials {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::UpdateChapCredentials', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateGatewayInformation {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::UpdateGatewayInformation', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateGatewaySoftwareNow {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::UpdateGatewaySoftwareNow', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateMaintenanceStartTime {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::UpdateMaintenanceStartTime', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateSnapshotSchedule {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::UpdateSnapshotSchedule', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateVTLDeviceType {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::StorageGateway::UpdateVTLDeviceType', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway - Perl Interface to AWS AWS Storage Gateway

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('StorageGateway')->new;
  my $res = $obj->Method(
    Arg1 => $val1,
    Arg2 => [ 'V1', 'V2' ],
    # if Arg3 is an object, the HashRef will be used as arguments to the constructor
    # of the arguments type
    Arg3 => { Att1 => 'Val1' },
    # if Arg4 is an array of objects, the HashRefs will be passed as arguments to
    # the constructor of the arguments type
    Arg4 => [ { Att1 => 'Val1'  }, { Att1 => 'Val2' } ],
  );

=head1 DESCRIPTION



AWS Storage Gateway Service

AWS Storage Gateway is the service that connects an on-premises
software appliance with cloud-based storage to provide seamless and
secure integration between an organization's on-premises IT environment
and AWS's storage infrastructure. The service enables you to securely
upload data to the AWS cloud for cost effective backup and rapid
disaster recovery.

Use the following links to get started using the I<AWS Storage Gateway
Service API Reference>:

=over

=item * AWS Storage Gateway Required Request Headers: Describes the
required headers that you must send with every POST request to AWS
Storage Gateway.

=item * Signing Requests: AWS Storage Gateway requires that you
authenticate every request you send; this topic describes how sign such
a request.

=item * Error Responses: Provides reference information about AWS
Storage Gateway errors.

=item * Operations in AWS Storage Gateway: Contains detailed
descriptions of all AWS Storage Gateway operations, their request
parameters, response elements, possible errors, and examples of
requests and responses.

=item * AWS Storage Gateway Regions and Endpoints: Provides a list of
each of the regions and endpoints available for use with AWS Storage
Gateway.

=back










=head1 METHODS

=head2 ActivateGateway(ActivationKey => Str, GatewayName => Str, GatewayRegion => Str, GatewayTimezone => Str, [GatewayType => Str, MediumChangerType => Str, TapeDriveType => Str])

Each argument is described in detail in: L<Paws::StorageGateway::ActivateGateway>

Returns: a L<Paws::StorageGateway::ActivateGatewayOutput> instance

  

This operation activates the gateway you previously deployed on your
host. For more information, see Activate the AWS Storage Gateway. In
the activation process, you specify information such as the region you
want to use for storing snapshots, the time zone for scheduled
snapshots the gateway snapshot schedule window, an activation key, and
a name for your gateway. The activation process also associates your
gateway with your account; for more information, see
UpdateGatewayInformation.

You must turn on the gateway VM before you can activate your gateway.











=head2 AddCache(DiskIds => ArrayRef[Str], GatewayARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::AddCache>

Returns: a L<Paws::StorageGateway::AddCacheOutput> instance

  

This operation configures one or more gateway local disks as cache for
a cached-volume gateway. This operation is supported only for the
gateway-cached volume architecture (see Storage Gateway Concepts).

In the request, you specify the gateway Amazon Resource Name (ARN) to
which you want to add cache, and one or more disk IDs that you want to
configure as cache.











=head2 AddUploadBuffer(DiskIds => ArrayRef[Str], GatewayARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::AddUploadBuffer>

Returns: a L<Paws::StorageGateway::AddUploadBufferOutput> instance

  

This operation configures one or more gateway local disks as upload
buffer for a specified gateway. This operation is supported for both
the gateway-stored and gateway-cached volume architectures.

In the request, you specify the gateway Amazon Resource Name (ARN) to
which you want to add upload buffer, and one or more disk IDs that you
want to configure as upload buffer.











=head2 AddWorkingStorage(DiskIds => ArrayRef[Str], GatewayARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::AddWorkingStorage>

Returns: a L<Paws::StorageGateway::AddWorkingStorageOutput> instance

  

This operation configures one or more gateway local disks as working
storage for a gateway. This operation is supported only for the
gateway-stored volume architecture. This operation is deprecated method
in cached-volumes API version (20120630). Use AddUploadBuffer instead.

Working storage is also referred to as upload buffer. You can also use
the AddUploadBuffer operation to add upload buffer to a stored-volume
gateway.

In the request, you specify the gateway Amazon Resource Name (ARN) to
which you want to add working storage, and one or more disk IDs that
you want to configure as working storage.











=head2 CancelArchival(GatewayARN => Str, TapeARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::CancelArchival>

Returns: a L<Paws::StorageGateway::CancelArchivalOutput> instance

  

Cancels archiving of a virtual tape to the virtual tape shelf (VTS)
after the archiving process is initiated.











=head2 CancelRetrieval(GatewayARN => Str, TapeARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::CancelRetrieval>

Returns: a L<Paws::StorageGateway::CancelRetrievalOutput> instance

  

Cancels retrieval of a virtual tape from the virtual tape shelf (VTS)
to a gateway after the retrieval process is initiated. The virtual tape
is returned to the VTS.











=head2 CreateCachediSCSIVolume(ClientToken => Str, GatewayARN => Str, NetworkInterfaceId => Str, TargetName => Str, VolumeSizeInBytes => Int, [SnapshotId => Str])

Each argument is described in detail in: L<Paws::StorageGateway::CreateCachediSCSIVolume>

Returns: a L<Paws::StorageGateway::CreateCachediSCSIVolumeOutput> instance

  

This operation creates a cached volume on a specified cached gateway.
This operation is supported only for the gateway-cached volume
architecture.

Cache storage must be allocated to the gateway before you can create a
cached volume. Use the AddCache operation to add cache storage to a
gateway.

In the request, you must specify the gateway, size of the volume in
bytes, the iSCSI target name, an IP address on which to expose the
target, and a unique client token. In response, AWS Storage Gateway
creates the volume and returns information about it such as the volume
Amazon Resource Name (ARN), its size, and the iSCSI target ARN that
initiators can use to connect to the volume target.











=head2 CreateSnapshot(SnapshotDescription => Str, VolumeARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::CreateSnapshot>

Returns: a L<Paws::StorageGateway::CreateSnapshotOutput> instance

  

This operation initiates a snapshot of a volume.

AWS Storage Gateway provides the ability to back up point-in-time
snapshots of your data to Amazon Simple Storage (S3) for durable
off-site recovery, as well as import the data to an Amazon Elastic
Block Store (EBS) volume in Amazon Elastic Compute Cloud (EC2). You can
take snapshots of your gateway volume on a scheduled or ad-hoc basis.
This API enables you to take ad-hoc snapshot. For more information, see
Working With Snapshots in the AWS Storage Gateway Console.

In the CreateSnapshot request you identify the volume by providing its
Amazon Resource Name (ARN). You must also provide description for the
snapshot. When AWS Storage Gateway takes the snapshot of specified
volume, the snapshot and description appears in the AWS Storage Gateway
Console. In response, AWS Storage Gateway returns you a snapshot ID.
You can use this snapshot ID to check the snapshot progress or later
use it when you want to create a volume from a snapshot.

To list or delete a snapshot, you must use the Amazon EC2 API. For more
information, see DescribeSnapshots or DeleteSnapshot in the EC2 API
reference.











=head2 CreateSnapshotFromVolumeRecoveryPoint(SnapshotDescription => Str, VolumeARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::CreateSnapshotFromVolumeRecoveryPoint>

Returns: a L<Paws::StorageGateway::CreateSnapshotFromVolumeRecoveryPointOutput> instance

  

This operation initiates a snapshot of a gateway from a volume recovery
point. This operation is supported only for the gateway-cached volume
architecture (see ).

A volume recovery point is a point in time at which all data of the
volume is consistent and from which you can create a snapshot. To get a
list of volume recovery point for gateway-cached volumes, use
ListVolumeRecoveryPoints.

In the C<CreateSnapshotFromVolumeRecoveryPoint> request, you identify
the volume by providing its Amazon Resource Name (ARN). You must also
provide a description for the snapshot. When AWS Storage Gateway takes
a snapshot of the specified volume, the snapshot and its description
appear in the AWS Storage Gateway console. In response, AWS Storage
Gateway returns you a snapshot ID. You can use this snapshot ID to
check the snapshot progress or later use it when you want to create a
volume from a snapshot.

To list or delete a snapshot, you must use the Amazon EC2 API. For more
information, in I<Amazon Elastic Compute Cloud API Reference>.











=head2 CreateStorediSCSIVolume(DiskId => Str, GatewayARN => Str, NetworkInterfaceId => Str, PreserveExistingData => Bool, TargetName => Str, [SnapshotId => Str])

Each argument is described in detail in: L<Paws::StorageGateway::CreateStorediSCSIVolume>

Returns: a L<Paws::StorageGateway::CreateStorediSCSIVolumeOutput> instance

  

This operation creates a volume on a specified gateway. This operation
is supported only for the gateway-stored volume architecture.

The size of the volume to create is inferred from the disk size. You
can choose to preserve existing data on the disk, create volume from an
existing snapshot, or create an empty volume. If you choose to create
an empty gateway volume, then any existing data on the disk is erased.

In the request you must specify the gateway and the disk information on
which you are creating the volume. In response, AWS Storage Gateway
creates the volume and returns volume information such as the volume
Amazon Resource Name (ARN), its size, and the iSCSI target ARN that
initiators can use to connect to the volume target.











=head2 CreateTapes(ClientToken => Str, GatewayARN => Str, NumTapesToCreate => Int, TapeBarcodePrefix => Str, TapeSizeInBytes => Int)

Each argument is described in detail in: L<Paws::StorageGateway::CreateTapes>

Returns: a L<Paws::StorageGateway::CreateTapesOutput> instance

  

Creates one or more virtual tapes. You write data to the virtual tapes
and then archive the tapes.

Cache storage must be allocated to the gateway before you can create
virtual tapes. Use the AddCache operation to add cache storage to a
gateway.











=head2 DeleteBandwidthRateLimit(BandwidthType => Str, GatewayARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::DeleteBandwidthRateLimit>

Returns: a L<Paws::StorageGateway::DeleteBandwidthRateLimitOutput> instance

  

This operation deletes the bandwidth rate limits of a gateway. You can
delete either the upload and download bandwidth rate limit, or you can
delete both. If you delete only one of the limits, the other limit
remains unchanged. To specify which gateway to work with, use the
Amazon Resource Name (ARN) of the gateway in your request.











=head2 DeleteChapCredentials(InitiatorName => Str, TargetARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::DeleteChapCredentials>

Returns: a L<Paws::StorageGateway::DeleteChapCredentialsOutput> instance

  

This operation deletes Challenge-Handshake Authentication Protocol
(CHAP) credentials for a specified iSCSI target and initiator pair.











=head2 DeleteGateway(GatewayARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::DeleteGateway>

Returns: a L<Paws::StorageGateway::DeleteGatewayOutput> instance

  

This operation deletes a gateway. To specify which gateway to delete,
use the Amazon Resource Name (ARN) of the gateway in your request. The
operation deletes the gateway; however, it does not delete the gateway
virtual machine (VM) from your host computer.

After you delete a gateway, you cannot reactivate it. Completed
snapshots of the gateway volumes are not deleted upon deleting the
gateway, however, pending snapshots will not complete. After you delete
a gateway, your next step is to remove it from your environment.

You no longer pay software charges after the gateway is deleted;
however, your existing Amazon EBS snapshots persist and you will
continue to be billed for these snapshots.E<Acirc> You can choose to
remove all remaining Amazon EBS snapshots by canceling your Amazon EC2
subscription.E<Acirc> If you prefer not to cancel your Amazon EC2
subscription, you can delete your snapshots using the Amazon EC2
console. For more information, see the AWS Storage Gateway Detail Page.











=head2 DeleteSnapshotSchedule(VolumeARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::DeleteSnapshotSchedule>

Returns: a L<Paws::StorageGateway::DeleteSnapshotScheduleOutput> instance

  

This operation deletes a snapshot of a volume.

You can take snapshots of your gateway volumes on a scheduled or ad-hoc
basis. This API enables you to delete a snapshot schedule for a volume.
For more information, see Working with Snapshots. In the
C<DeleteSnapshotSchedule> request, you identify the volume by providing
its Amazon Resource Name (ARN).

To list or delete a snapshot, you must use the Amazon EC2 API. in
I<Amazon Elastic Compute Cloud API Reference>.











=head2 DeleteTape(GatewayARN => Str, TapeARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::DeleteTape>

Returns: a L<Paws::StorageGateway::DeleteTapeOutput> instance

  

Deletes the specified virtual tape.











=head2 DeleteTapeArchive(TapeARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::DeleteTapeArchive>

Returns: a L<Paws::StorageGateway::DeleteTapeArchiveOutput> instance

  

Deletes the specified virtual tape from the virtual tape shelf (VTS).











=head2 DeleteVolume(VolumeARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::DeleteVolume>

Returns: a L<Paws::StorageGateway::DeleteVolumeOutput> instance

  

This operation delete the specified gateway volume that you previously
created using the CreateStorediSCSIVolume API. For gateway-stored
volumes, the local disk that was configured as the storage volume is
not deleted. You can reuse the local disk to create another storage
volume.

Before you delete a gateway volume, make sure there are no iSCSI
connections to the volume you are deleting. You should also make sure
there is no snapshot in progress. You can use the Amazon Elastic
Compute Cloud (Amazon EC2) API to query snapshots on the volume you are
deleting and check the snapshot status. For more information, go to
DescribeSnapshots in the I<Amazon Elastic Compute Cloud API Reference>.

In the request, you must provide the Amazon Resource Name (ARN) of the
storage volume you want to delete.











=head2 DescribeBandwidthRateLimit(GatewayARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::DescribeBandwidthRateLimit>

Returns: a L<Paws::StorageGateway::DescribeBandwidthRateLimitOutput> instance

  

This operation returns the bandwidth rate limits of a gateway. By
default, these limits are not set, which means no bandwidth rate
limiting is in effect.

This operation only returns a value for a bandwidth rate limit only if
the limit is set. If no limits are set for the gateway, then this
operation returns only the gateway ARN in the response body. To specify
which gateway to describe, use the Amazon Resource Name (ARN) of the
gateway in your request.











=head2 DescribeCache(GatewayARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::DescribeCache>

Returns: a L<Paws::StorageGateway::DescribeCacheOutput> instance

  

This operation returns information about the cache of a gateway. This
operation is supported only for the gateway-cached volume architecture.

The response includes disk IDs that are configured as cache, and it
includes the amount of cache allocated and used.











=head2 DescribeCachediSCSIVolumes(VolumeARNs => ArrayRef[Str])

Each argument is described in detail in: L<Paws::StorageGateway::DescribeCachediSCSIVolumes>

Returns: a L<Paws::StorageGateway::DescribeCachediSCSIVolumesOutput> instance

  

This operation returns a description of the gateway volumes specified
in the request. This operation is supported only for the gateway-cached
volume architecture.

The list of gateway volumes in the request must be from one gateway. In
the response Amazon Storage Gateway returns volume information sorted
by volume Amazon Resource Name (ARN).











=head2 DescribeChapCredentials(TargetARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::DescribeChapCredentials>

Returns: a L<Paws::StorageGateway::DescribeChapCredentialsOutput> instance

  

This operation returns an array of Challenge-Handshake Authentication
Protocol (CHAP) credentials information for a specified iSCSI target,
one for each target-initiator pair.











=head2 DescribeGatewayInformation(GatewayARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::DescribeGatewayInformation>

Returns: a L<Paws::StorageGateway::DescribeGatewayInformationOutput> instance

  

This operation returns metadata about a gateway such as its name,
network interfaces, configured time zone, and the state (whether the
gateway is running or not). To specify which gateway to describe, use
the Amazon Resource Name (ARN) of the gateway in your request.











=head2 DescribeMaintenanceStartTime(GatewayARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::DescribeMaintenanceStartTime>

Returns: a L<Paws::StorageGateway::DescribeMaintenanceStartTimeOutput> instance

  

This operation returns your gateway's weekly maintenance start time
including the day and time of the week. Note that values are in terms
of the gateway's time zone.











=head2 DescribeSnapshotSchedule(VolumeARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::DescribeSnapshotSchedule>

Returns: a L<Paws::StorageGateway::DescribeSnapshotScheduleOutput> instance

  

This operation describes the snapshot schedule for the specified
gateway volume. The snapshot schedule information includes intervals at
which snapshots are automatically initiated on the volume.











=head2 DescribeStorediSCSIVolumes(VolumeARNs => ArrayRef[Str])

Each argument is described in detail in: L<Paws::StorageGateway::DescribeStorediSCSIVolumes>

Returns: a L<Paws::StorageGateway::DescribeStorediSCSIVolumesOutput> instance

  

This operation returns the description of the gateway volumes specified
in the request. The list of gateway volumes in the request must be from
one gateway. In the response Amazon Storage Gateway returns volume
information sorted by volume ARNs.











=head2 DescribeTapeArchives([Limit => Int, Marker => Str, TapeARNs => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::StorageGateway::DescribeTapeArchives>

Returns: a L<Paws::StorageGateway::DescribeTapeArchivesOutput> instance

  

Returns a description of specified virtual tapes in the virtual tape
shelf (VTS).

If a specific C<TapeARN> is not specified, AWS Storage Gateway returns
a description of all virtual tapes found in the VTS associated with
your account.











=head2 DescribeTapeRecoveryPoints(GatewayARN => Str, [Limit => Int, Marker => Str])

Each argument is described in detail in: L<Paws::StorageGateway::DescribeTapeRecoveryPoints>

Returns: a L<Paws::StorageGateway::DescribeTapeRecoveryPointsOutput> instance

  

Returns a list of virtual tape recovery points that are available for
the specified gateway-VTL.

A recovery point is a point in time view of a virtual tape at which all
the data on the virtual tape is consistent. If your gateway crashes,
virtual tapes that have recovery points can be recovered to a new
gateway.











=head2 DescribeTapes(GatewayARN => Str, [Limit => Int, Marker => Str, TapeARNs => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::StorageGateway::DescribeTapes>

Returns: a L<Paws::StorageGateway::DescribeTapesOutput> instance

  

Returns a description of the specified Amazon Resource Name (ARN) of
virtual tapes. If a C<TapeARN> is not specified, returns a description
of all virtual tapes associated with the specified gateway.











=head2 DescribeUploadBuffer(GatewayARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::DescribeUploadBuffer>

Returns: a L<Paws::StorageGateway::DescribeUploadBufferOutput> instance

  

This operation returns information about the upload buffer of a
gateway. This operation is supported for both the gateway-stored and
gateway-cached volume architectures.

The response includes disk IDs that are configured as upload buffer
space, and it includes the amount of upload buffer space allocated and
used.











=head2 DescribeVTLDevices(GatewayARN => Str, [Limit => Int, Marker => Str, VTLDeviceARNs => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::StorageGateway::DescribeVTLDevices>

Returns: a L<Paws::StorageGateway::DescribeVTLDevicesOutput> instance

  

Returns a description of virtual tape library (VTL) devices for the
specified gateway. In the response, AWS Storage Gateway returns VTL
device information.

The list of VTL devices must be from one gateway.











=head2 DescribeWorkingStorage(GatewayARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::DescribeWorkingStorage>

Returns: a L<Paws::StorageGateway::DescribeWorkingStorageOutput> instance

  

This operation returns information about the working storage of a
gateway. This operation is supported only for the gateway-stored volume
architecture. This operation is deprecated in cached-volumes API
version (20120630). Use DescribeUploadBuffer instead.

Working storage is also referred to as upload buffer. You can also use
the DescribeUploadBuffer operation to add upload buffer to a
stored-volume gateway.

The response includes disk IDs that are configured as working storage,
and it includes the amount of working storage allocated and used.











=head2 DisableGateway(GatewayARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::DisableGateway>

Returns: a L<Paws::StorageGateway::DisableGatewayOutput> instance

  

Disables a gateway when the gateway is no longer functioning. For
example, if your gateway VM is damaged, you can disable the gateway so
you can recover virtual tapes.

Use this operation for a gateway-VTL that is not reachable or not
functioning.

Once a gateway is disabled it cannot be enabled.











=head2 ListGateways([Limit => Int, Marker => Str])

Each argument is described in detail in: L<Paws::StorageGateway::ListGateways>

Returns: a L<Paws::StorageGateway::ListGatewaysOutput> instance

  

This operation lists gateways owned by an AWS account in a region
specified in the request. The returned list is ordered by gateway
Amazon Resource Name (ARN).

By default, the operation returns a maximum of 100 gateways. This
operation supports pagination that allows you to optionally reduce the
number of gateways returned in a response.

If you have more gateways than are returned in a response-that is, the
response returns only a truncated list of your gateways-the response
contains a marker that you can specify in your next request to fetch
the next page of gateways.











=head2 ListLocalDisks(GatewayARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::ListLocalDisks>

Returns: a L<Paws::StorageGateway::ListLocalDisksOutput> instance

  

This operation returns a list of the gateway's local disks. To specify
which gateway to describe, you use the Amazon Resource Name (ARN) of
the gateway in the body of the request.

The request returns a list of all disks, specifying which are
configured as working storage, cache storage, or stored volume or not
configured at all. The response includes a C<DiskStatus> field. This
field can have a value of present (the disk is available to use),
missing (the disk is no longer connected to the gateway), or mismatch
(the disk node is occupied by a disk that has incorrect metadata or the
disk content is corrupted).











=head2 ListVolumeInitiators(VolumeARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::ListVolumeInitiators>

Returns: a L<Paws::StorageGateway::ListVolumeInitiatorsOutput> instance

  

This operation lists iSCSI initiators that are connected to a volume.
You can use this operation to determine whether a volume is being used
or not.











=head2 ListVolumeRecoveryPoints(GatewayARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::ListVolumeRecoveryPoints>

Returns: a L<Paws::StorageGateway::ListVolumeRecoveryPointsOutput> instance

  

This operation lists the recovery points for a specified gateway. This
operation is supported only for the gateway-cached volume architecture.

Each gateway-cached volume has one recovery point. A volume recovery
point is a point in time at which all data of the volume is consistent
and from which you can create a snapshot. To create a snapshot from a
volume recovery point use the CreateSnapshotFromVolumeRecoveryPoint
operation.











=head2 ListVolumes(GatewayARN => Str, [Limit => Int, Marker => Str])

Each argument is described in detail in: L<Paws::StorageGateway::ListVolumes>

Returns: a L<Paws::StorageGateway::ListVolumesOutput> instance

  

This operation lists the iSCSI stored volumes of a gateway. Results are
sorted by volume ARN. The response includes only the volume ARNs. If
you want additional volume information, use the
DescribeStorediSCSIVolumes API.

The operation supports pagination. By default, the operation returns a
maximum of up to 100 volumes. You can optionally specify the C<Limit>
field in the body to limit the number of volumes in the response. If
the number of volumes returned in the response is truncated, the
response includes a Marker field. You can use this Marker value in your
subsequent request to retrieve the next set of volumes.











=head2 ResetCache(GatewayARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::ResetCache>

Returns: a L<Paws::StorageGateway::ResetCacheOutput> instance

  

This operation resets all cache disks that have encountered a error and
makes the disks available for reconfiguration as cache storage. If your
cache disk encounters a error, the gateway prevents read and write
operations on virtual tapes in the gateway. For example, an error can
occur when a disk is corrupted or removed from the gateway. When a
cache is reset, the gateway loses its cache storage. At this point you
can reconfigure the disks as cache disks.

If the cache disk you are resetting contains data that has not been
uploaded to Amazon S3 yet, that data can be lost. After you reset cache
disks, there will be no configured cache disks left in the gateway, so
you must configure at least one new cache disk for your gateway to
function properly.











=head2 RetrieveTapeArchive(GatewayARN => Str, TapeARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::RetrieveTapeArchive>

Returns: a L<Paws::StorageGateway::RetrieveTapeArchiveOutput> instance

  

Retrieves an archived virtual tape from the virtual tape shelf (VTS) to
a gateway-VTL. Virtual tapes archived in the VTS are not associated
with any gateway. However after a tape is retrieved, it is associated
with a gateway, even though it is also listed in the VTS.

Once a tape is successfully retrieved to a gateway, it cannot be
retrieved again to another gateway. You must archive the tape again
before you can retrieve it to another gateway.











=head2 RetrieveTapeRecoveryPoint(GatewayARN => Str, TapeARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::RetrieveTapeRecoveryPoint>

Returns: a L<Paws::StorageGateway::RetrieveTapeRecoveryPointOutput> instance

  

Retrieves the recovery point for the specified virtual tape.

A recovery point is a point in time view of a virtual tape at which all
the data on the tape is consistent. If your gateway crashes, virtual
tapes that have recovery points can be recovered to a new gateway.

The virtual tape can be retrieved to only one gateway. The retrieved
tape is read-only. The virtual tape can be retrieved to only a
gateway-VTL. There is no charge for retrieving recovery points.











=head2 ShutdownGateway(GatewayARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::ShutdownGateway>

Returns: a L<Paws::StorageGateway::ShutdownGatewayOutput> instance

  

This operation shuts down a gateway. To specify which gateway to shut
down, use the Amazon Resource Name (ARN) of the gateway in the body of
your request.

The operation shuts down the gateway service component running in the
storage gateway's virtual machine (VM) and not the VM.

If you want to shut down the VM, it is recommended that you first shut
down the gateway component in the VM to avoid unpredictable conditions.

After the gateway is shutdown, you cannot call any other API except
StartGateway, DescribeGatewayInformation, and ListGateways. For more
information, see ActivateGateway. Your applications cannot read from or
write to the gateway's storage volumes, and there are no snapshots
taken.

When you make a shutdown request, you will get a C<200 OK> success
response immediately. However, it might take some time for the gateway
to shut down. You can call the DescribeGatewayInformation API to check
the status. For more information, see ActivateGateway.

If do not intend to use the gateway again, you must delete the gateway
(using DeleteGateway) to no longer pay software charges associated with
the gateway.











=head2 StartGateway(GatewayARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::StartGateway>

Returns: a L<Paws::StorageGateway::StartGatewayOutput> instance

  

This operation starts a gateway that you previously shut down (see
ShutdownGateway). After the gateway starts, you can then make other API
calls, your applications can read from or write to the gateway's
storage volumes and you will be able to take snapshot backups.

When you make a request, you will get a 200 OK success response
immediately. However, it might take some time for the gateway to be
ready. You should call DescribeGatewayInformation and check the status
before making any additional API calls. For more information, see
ActivateGateway.

To specify which gateway to start, use the Amazon Resource Name (ARN)
of the gateway in your request.











=head2 UpdateBandwidthRateLimit(GatewayARN => Str, [AverageDownloadRateLimitInBitsPerSec => Int, AverageUploadRateLimitInBitsPerSec => Int])

Each argument is described in detail in: L<Paws::StorageGateway::UpdateBandwidthRateLimit>

Returns: a L<Paws::StorageGateway::UpdateBandwidthRateLimitOutput> instance

  

This operation updates the bandwidth rate limits of a gateway. You can
update both the upload and download bandwidth rate limit or specify
only one of the two. If you don't set a bandwidth rate limit, the
existing rate limit remains.

By default, a gateway's bandwidth rate limits are not set. If you don't
set any limit, the gateway does not have any limitations on its
bandwidth usage and could potentially use the maximum available
bandwidth.

To specify which gateway to update, use the Amazon Resource Name (ARN)
of the gateway in your request.











=head2 UpdateChapCredentials(InitiatorName => Str, SecretToAuthenticateInitiator => Str, TargetARN => Str, [SecretToAuthenticateTarget => Str])

Each argument is described in detail in: L<Paws::StorageGateway::UpdateChapCredentials>

Returns: a L<Paws::StorageGateway::UpdateChapCredentialsOutput> instance

  

This operation updates the Challenge-Handshake Authentication Protocol
(CHAP) credentials for a specified iSCSI target. By default, a gateway
does not have CHAP enabled; however, for added security, you might use
it.

When you update CHAP credentials, all existing connections on the
target are closed and initiators must reconnect with the new
credentials.











=head2 UpdateGatewayInformation(GatewayARN => Str, [GatewayName => Str, GatewayTimezone => Str])

Each argument is described in detail in: L<Paws::StorageGateway::UpdateGatewayInformation>

Returns: a L<Paws::StorageGateway::UpdateGatewayInformationOutput> instance

  

This operation updates a gateway's metadata, which includes the
gateway's name and time zone. To specify which gateway to update, use
the Amazon Resource Name (ARN) of the gateway in your request.











=head2 UpdateGatewaySoftwareNow(GatewayARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::UpdateGatewaySoftwareNow>

Returns: a L<Paws::StorageGateway::UpdateGatewaySoftwareNowOutput> instance

  

This operation updates the gateway virtual machine (VM) software. The
request immediately triggers the software update.

When you make this request, you get a C<200 OK> success response
immediately. However, it might take some time for the update to
complete. You can call DescribeGatewayInformation to verify the gateway
is in the C<STATE_RUNNING> state. A software update forces a system
restart of your gateway. You can minimize the chance of any disruption
to your applications by increasing your iSCSI Initiators' timeouts. For
more information about increasing iSCSI Initiator timeouts for Windows
and Linux, see Customizing Your Windows iSCSI Settings and Customizing
Your Linux iSCSI Settings, respectively.











=head2 UpdateMaintenanceStartTime(DayOfWeek => Int, GatewayARN => Str, HourOfDay => Int, MinuteOfHour => Int)

Each argument is described in detail in: L<Paws::StorageGateway::UpdateMaintenanceStartTime>

Returns: a L<Paws::StorageGateway::UpdateMaintenanceStartTimeOutput> instance

  

This operation updates a gateway's weekly maintenance start time
information, including day and time of the week. The maintenance time
is the time in your gateway's time zone.











=head2 UpdateSnapshotSchedule(RecurrenceInHours => Int, StartAt => Int, VolumeARN => Str, [Description => Str])

Each argument is described in detail in: L<Paws::StorageGateway::UpdateSnapshotSchedule>

Returns: a L<Paws::StorageGateway::UpdateSnapshotScheduleOutput> instance

  

This operation updates a snapshot schedule configured for a gateway
volume.

The default snapshot schedule for volume is once every 24 hours,
starting at the creation time of the volume. You can use this API to
change the snapshot schedule configured for the volume.

In the request you must identify the gateway volume whose snapshot
schedule you want to update, and the schedule information, including
when you want the snapshot to begin on a day and the frequency (in
hours) of snapshots.











=head2 UpdateVTLDeviceType(DeviceType => Str, VTLDeviceARN => Str)

Each argument is described in detail in: L<Paws::StorageGateway::UpdateVTLDeviceType>

Returns: a L<Paws::StorageGateway::UpdateVTLDeviceTypeOutput> instance

  

This operation updates the type of medium changer in a gateway-VTL.
When you activate a gateway-VTL, you select a medium changer type for
the gateway-VTL. This operation enables you to select a different type
of medium changer after a gateway-VTL is activated.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

