
package Paws::StorageGateway::ListVolumesOutput {
  use Moose;
  has GatewayARN => (is => 'ro', isa => 'Str');
  has Marker => (is => 'ro', isa => 'Str');
  has VolumeInfos => (is => 'ro', isa => 'ArrayRef[Paws::StorageGateway::VolumeInfo]');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::ListVolumesOutput

=head1 ATTRIBUTES

=head2 GatewayARN => Str

  
=head2 Marker => Str

  
=head2 VolumeInfos => ArrayRef[Paws::StorageGateway::VolumeInfo]

  


=cut

1;