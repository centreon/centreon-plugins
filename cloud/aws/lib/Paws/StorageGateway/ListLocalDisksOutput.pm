
package Paws::StorageGateway::ListLocalDisksOutput {
  use Moose;
  has Disks => (is => 'ro', isa => 'ArrayRef[Paws::StorageGateway::Disk]');
  has GatewayARN => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::ListLocalDisksOutput

=head1 ATTRIBUTES

=head2 Disks => ArrayRef[Paws::StorageGateway::Disk]

  
=head2 GatewayARN => Str

  


=cut

1;