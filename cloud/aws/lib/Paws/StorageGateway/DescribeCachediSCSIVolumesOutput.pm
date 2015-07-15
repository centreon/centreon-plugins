
package Paws::StorageGateway::DescribeCachediSCSIVolumesOutput {
  use Moose;
  has CachediSCSIVolumes => (is => 'ro', isa => 'ArrayRef[Paws::StorageGateway::CachediSCSIVolume]');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::DescribeCachediSCSIVolumesOutput

=head1 ATTRIBUTES

=head2 CachediSCSIVolumes => ArrayRef[Paws::StorageGateway::CachediSCSIVolume]

  

An array of objects where each object contains metadata about one
cached volume.











=cut

1;