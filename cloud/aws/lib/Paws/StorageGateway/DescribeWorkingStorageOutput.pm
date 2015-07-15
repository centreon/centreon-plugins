
package Paws::StorageGateway::DescribeWorkingStorageOutput {
  use Moose;
  has DiskIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has GatewayARN => (is => 'ro', isa => 'Str');
  has WorkingStorageAllocatedInBytes => (is => 'ro', isa => 'Int');
  has WorkingStorageUsedInBytes => (is => 'ro', isa => 'Int');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::DescribeWorkingStorageOutput

=head1 ATTRIBUTES

=head2 DiskIds => ArrayRef[Str]

  

An array of the gateway's local disk IDs that are configured as working
storage. Each local disk ID is specified as a string (minimum length of
1 and maximum length of 300). If no local disks are configured as
working storage, then the DiskIds array is empty.









=head2 GatewayARN => Str

  
=head2 WorkingStorageAllocatedInBytes => Int

  

The total working storage in bytes allocated for the gateway. If no
working storage is configured for the gateway, this field returns 0.









=head2 WorkingStorageUsedInBytes => Int

  

The total working storage in bytes in use by the gateway. If no working
storage is configured for the gateway, this field returns 0.











=cut

1;