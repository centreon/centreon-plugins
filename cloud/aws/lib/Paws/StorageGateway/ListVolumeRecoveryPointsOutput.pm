
package Paws::StorageGateway::ListVolumeRecoveryPointsOutput {
  use Moose;
  has GatewayARN => (is => 'ro', isa => 'Str');
  has VolumeRecoveryPointInfos => (is => 'ro', isa => 'ArrayRef[Paws::StorageGateway::VolumeRecoveryPointInfo]');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::ListVolumeRecoveryPointsOutput

=head1 ATTRIBUTES

=head2 GatewayARN => Str

  
=head2 VolumeRecoveryPointInfos => ArrayRef[Paws::StorageGateway::VolumeRecoveryPointInfo]

  


=cut

1;